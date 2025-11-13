import * as XLSX from 'xlsx';

export interface ImportValidationError {
  row: number;
  field: string;
  message: string;
  severity: 'error' | 'warning';
}

export interface MappingTemplate {
  id: string;
  name: string;
  importType: string;
  columnMappings: Record<string, string>;
  isDefault: boolean;
}

export interface ImportJob {
  id: string;
  fileName: string;
  importType: string;
  status: 'parsing' | 'validating' | 'staging' | 'committing' | 'completed' | 'failed';
  progress: number;
  totalRows: number;
  validRows: number;
  errorRows: number;
  warnings: number;
  errors: ImportValidationError[];
  mappingTemplate?: MappingTemplate;
  autoRunCalculation: boolean;
  duplicateStrategy: 'reject' | 'allow' | 'update';
}

export interface ParsedExcelData {
  headers: string[];
  rows: Record<string, any>[];
  totalRows: number;
}

// Standard field mappings for auto-detection
const FIELD_MAPPINGS = {
  contributions: {
    investor_id: ['investor_id', 'investor id', 'investor', 'client_id', 'client id'],
    investor_name: ['investor_name', 'investor name', 'client_name', 'client name'],
    fund_id: ['fund_id', 'fund id', 'fund', 'vehicle_id', 'vehicle'],
    fund_name: ['fund_name', 'fund name', 'vehicle_name', 'vehicle name'],
    date: ['date', 'contribution_date', 'investment_date', 'transaction_date'],
    amount: ['amount', 'contribution_amount', 'investment_amount', 'value'],
    currency: ['currency', 'ccy', 'curr'],
    source_channel: ['source_channel', 'source', 'channel', 'introducer'],
    external_ref: ['external_ref', 'reference', 'ref', 'transaction_id', 'tx_id'],
    notes: ['notes', 'comments', 'description', 'memo']
  },
  investors: {
    investor_id: ['investor_id', 'id', 'client_id'],
    name: ['name', 'investor_name', 'client_name', 'full_name'],
    email: ['email', 'email_address'],
    tax_country: ['tax_country', 'country', 'jurisdiction', 'domicile'],
    introduced_by: ['introduced_by', 'introducer', 'referrer', 'source'],
    tags: ['tags', 'categories', 'labels', 'classification']
  },
  credits: {
    investor_id: ['investor_id', 'investor', 'client_id'],
    fund_id: ['fund_id', 'fund', 'vehicle_id'],
    credit_type: ['credit_type', 'type', 'adjustment_type'],
    amount: ['amount', 'credit_amount', 'adjustment_amount'],
    currency: ['currency', 'ccy'],
    date_posted: ['date_posted', 'date', 'effective_date'],
    reason: ['reason', 'notes', 'description'],
    external_ref: ['external_ref', 'reference', 'ref']
  }
};

// Required fields by import type
const REQUIRED_FIELDS = {
  contributions: ['investor_id', 'fund_id', 'date', 'amount', 'currency'],
  investors: ['investor_id', 'name'],
  credits: ['investor_id', 'fund_id', 'amount', 'currency', 'date_posted', 'credit_type']
};

// Currency codes (ISO 4217 subset)
const VALID_CURRENCIES = ['USD', 'EUR', 'GBP', 'ILS', 'CAD', 'AUD', 'CHF', 'JPY'];

export class ExcelImportEngine {
  private progressCallback?: (progress: number, status: string) => void;

  constructor(progressCallback?: (progress: number, status: string) => void) {
    this.progressCallback = progressCallback;
  }

  private updateProgress(progress: number, status: string) {
    if (this.progressCallback) {
      this.progressCallback(progress, status);
    }
  }

  /**
   * Parse Excel file and extract data
   */
  async parseExcelFile(file: File): Promise<ParsedExcelData> {
    this.updateProgress(10, 'Reading file...');
    
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      
      reader.onload = (e) => {
        try {
          const data = e.target?.result;
          const workbook = XLSX.read(data, { type: 'binary' });
          
          // Use first sheet
          const sheetName = workbook.SheetNames[0];
          const worksheet = workbook.Sheets[sheetName];
          
          // Convert to JSON with header row
          const jsonData = XLSX.utils.sheet_to_json(worksheet, { 
            header: 1,
            defval: '',
            blankrows: false 
          }) as any[][];
          
          if (jsonData.length < 2) {
            throw new Error('File must contain a header row and at least one data row');
          }
          
          const headers = jsonData[0].map(h => String(h).trim());
          const rows = jsonData.slice(1).map((row, index) => {
            const rowData: Record<string, any> = {};
            headers.forEach((header, colIndex) => {
              rowData[header] = row[colIndex] || '';
            });
            rowData.__row_number = index + 2; // Excel row number (1-indexed + header)
            return rowData;
          });
          
          this.updateProgress(30, 'File parsed successfully');
          
          resolve({
            headers,
            rows,
            totalRows: rows.length
          });
          
        } catch (error) {
          reject(new Error(`Failed to parse Excel file: ${error}`));
        }
      };
      
      reader.onerror = () => reject(new Error('Failed to read file'));
      reader.readAsBinaryString(file);
    });
  }

  /**
   * Auto-detect column mappings based on headers
   */
  autoDetectMappings(headers: string[], importType: string): Record<string, string> {
    const mappings: Record<string, string> = {};
    const fieldMappings = FIELD_MAPPINGS[importType as keyof typeof FIELD_MAPPINGS];
    
    if (!fieldMappings) return mappings;
    
    // Normalize headers for comparison
    const normalizedHeaders = headers.map(h => h.toLowerCase().trim().replace(/[_\s]+/g, '_'));
    
    Object.entries(fieldMappings).forEach(([field, variants]) => {
      const matchedHeader = headers.find((header, index) => {
        const normalized = normalizedHeaders[index];
        return variants.some(variant => 
          normalized === variant.toLowerCase().replace(/[_\s]+/g, '_')
        );
      });
      
      if (matchedHeader) {
        mappings[matchedHeader] = field;
      }
    });
    
    this.updateProgress(40, 'Column mappings detected');
    return mappings;
  }

  /**
   * Validate mapped data according to business rules
   */
  validateMappedData(
    rows: Record<string, any>[], 
    mappings: Record<string, string>, 
    importType: string
  ): ImportValidationError[] {
    const errors: ImportValidationError[] = [];
    const requiredFields = REQUIRED_FIELDS[importType as keyof typeof REQUIRED_FIELDS] || [];
    
    this.updateProgress(50, 'Validating data...');
    
    rows.forEach((row, index) => {
      const rowNumber = row.__row_number || index + 2;
      
      // Map row data to standard fields
      const mappedRow: Record<string, any> = {};
      Object.entries(mappings).forEach(([excelColumn, field]) => {
        mappedRow[field] = row[excelColumn];
      });
      
      // Check required fields
      requiredFields.forEach(field => {
        const value = mappedRow[field];
        if (!value || String(value).trim() === '') {
          errors.push({
            row: rowNumber,
            field,
            message: `Required field '${field}' is missing or empty`,
            severity: 'error'
          });
        }
      });
      
      // Validate specific field formats
      this.validateFieldFormats(mappedRow, rowNumber, errors, importType);
    });
    
    this.updateProgress(80, 'Validation complete');
    return errors;
  }

  private validateFieldFormats(
    row: Record<string, any>, 
    rowNumber: number, 
    errors: ImportValidationError[], 
    importType: string
  ) {
    // Date validation
    if (row.date) {
      const dateValue = this.parseDate(row.date);
      if (!dateValue) {
        errors.push({
          row: rowNumber,
          field: 'date',
          message: `Invalid date format: ${row.date}`,
          severity: 'error'
        });
      } else if (dateValue > new Date()) {
        errors.push({
          row: rowNumber,
          field: 'date',
          message: `Future dates not allowed: ${row.date}`,
          severity: 'error'
        });
      }
    }
    
    // Amount validation
    if (row.amount !== undefined) {
      const amount = this.parseAmount(row.amount);
      if (amount === null) {
        errors.push({
          row: rowNumber,
          field: 'amount',
          message: `Invalid amount format: ${row.amount}`,
          severity: 'error'
        });
      } else if (importType === 'contributions' && amount <= 0) {
        errors.push({
          row: rowNumber,
          field: 'amount',
          message: `Amount must be positive: ${row.amount}`,
          severity: 'error'
        });
      }
    }
    
    // Currency validation
    if (row.currency) {
      const currency = String(row.currency).toUpperCase().trim();
      if (!VALID_CURRENCIES.includes(currency)) {
        errors.push({
          row: rowNumber,
          field: 'currency',
          message: `Invalid currency code: ${row.currency}. Must be one of: ${VALID_CURRENCIES.join(', ')}`,
          severity: 'error'
        });
      }
    }
    
    // Email validation for investors
    if (importType === 'investors' && row.email) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(String(row.email))) {
        errors.push({
          row: rowNumber,
          field: 'email',
          message: `Invalid email format: ${row.email}`,
          severity: 'warning'
        });
      }
    }
  }

  private parseDate(value: any): Date | null {
    if (!value) return null;
    
    // Handle Excel serial dates
    if (typeof value === 'number') {
      const excelEpoch = new Date(1900, 0, 1);
      const date = new Date(excelEpoch.getTime() + (value - 2) * 24 * 60 * 60 * 1000);
      return isNaN(date.getTime()) ? null : date;
    }
    
    // Handle string dates
    const dateStr = String(value).trim();
    const date = new Date(dateStr);
    return isNaN(date.getTime()) ? null : date;
  }

  private parseAmount(value: any): number | null {
    if (value === null || value === undefined || value === '') return null;
    
    // Remove currency symbols and commas
    const cleanValue = String(value)
      .replace(/[$£€¥₪,\s]/g, '')
      .replace(/[()]/g, '') // Remove parentheses
      .trim();
    
    const num = parseFloat(cleanValue);
    return isNaN(num) ? null : num;
  }

  /**
   * Create error report for download
   */
  createErrorReport(
    originalData: ParsedExcelData, 
    errors: ImportValidationError[], 
    mappings: Record<string, string>
  ): Uint8Array {
    // Add error column to original data
    const errorsByRow = errors.reduce((acc, error) => {
      if (!acc[error.row]) acc[error.row] = [];
      acc[error.row].push(`${error.field}: ${error.message}`);
      return acc;
    }, {} as Record<number, string[]>);
    
    const newHeaders = [...originalData.headers, '__errors'];
    const newRows = originalData.rows.map((row, index) => {
      const rowNumber = row.__row_number || index + 2;
      const rowErrors = errorsByRow[rowNumber] || [];
      return {
        ...row,
        __errors: rowErrors.join('; ')
      };
    });
    
    // Create new workbook
    const worksheet = XLSX.utils.json_to_sheet(newRows, { header: newHeaders });
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Import Errors');
    
    return XLSX.write(workbook, { type: 'array', bookType: 'xlsx' });
  }

  /**
   * Generate mapping suggestions based on unmapped columns
   */
  suggestMappings(
    headers: string[], 
    existingMappings: Record<string, string>, 
    importType: string
  ): Record<string, string[]> {
    const suggestions: Record<string, string[]> = {};
    const fieldMappings = FIELD_MAPPINGS[importType as keyof typeof FIELD_MAPPINGS];
    
    if (!fieldMappings) return suggestions;
    
    const unmappedHeaders = headers.filter(h => !existingMappings[h]);
    const unmappedFields = Object.keys(fieldMappings).filter(f => 
      !Object.values(existingMappings).includes(f)
    );
    
    unmappedHeaders.forEach(header => {
      const headerNormalized = header.toLowerCase().trim().replace(/[_\s]+/g, '_');
      const matches = unmappedFields.filter(field => {
        const variants = fieldMappings[field as keyof typeof fieldMappings] || [];
        return variants.some(variant => 
          headerNormalized.includes(variant.toLowerCase().replace(/[_\s]+/g, '_')) ||
          variant.toLowerCase().replace(/[_\s]+/g, '_').includes(headerNormalized)
        );
      });
      
      if (matches.length > 0) {
        suggestions[header] = matches;
      }
    });
    
    return suggestions;
  }
}