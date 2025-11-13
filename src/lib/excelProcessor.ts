import * as XLSX from 'xlsx';

export interface ExcelColumn {
  key: string;
  label: string;
  required: boolean;
  type: 'text' | 'number' | 'date' | 'email';
  example?: string;
}

export interface ColumnMapping {
  [excelColumn: string]: string; // Maps Excel column to our field key
}

export interface ValidationError {
  row: number;
  column: string;
  value: any;
  message: string;
}

export interface ProcessedExcelData {
  headers: string[];
  data: any[];
  totalRows: number;
  validationErrors: ValidationError[];
}

// Expected columns for investor distributions
export const DISTRIBUTION_COLUMNS: ExcelColumn[] = [
  { key: 'investor_name', label: 'Investor Name', required: true, type: 'text', example: 'Smith Holdings LLC' },
  { key: 'fund_name', label: 'Fund Name', required: false, type: 'text', example: 'Growth Fund I' },
  { key: 'distribution_amount', label: 'Distribution Amount', required: true, type: 'number', example: '50000' },
  { key: 'distribution_date', label: 'Distribution Date', required: false, type: 'date', example: '2024-03-15' },
  { key: 'distributor_name', label: 'Distributor', required: false, type: 'text', example: 'Aventine Advisors' },
  { key: 'referrer_name', label: 'Referrer', required: false, type: 'text', example: 'Walden Partners' },
  { key: 'partner_name', label: 'Partner', required: false, type: 'text', example: 'Strategic Partners' },
];

// Debug log to verify module is loading
console.log('Excel processor module loaded with DISTRIBUTION_COLUMNS:', DISTRIBUTION_COLUMNS.length, 'columns');

export class ExcelProcessor {
  /**
   * Read and parse Excel file
   */
  static async parseExcelFile(file: File): Promise<ProcessedExcelData> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      
      reader.onload = (e) => {
        try {
          const arrayBuffer = e.target?.result as ArrayBuffer;
          const workbook = XLSX.read(arrayBuffer, { type: 'array' });
          const sheetName = workbook.SheetNames[0];
          const worksheet = workbook.Sheets[sheetName];
          
          // Convert to JSON with headers
          const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 }) as any[][];
          
          if (jsonData.length === 0) {
            throw new Error('The Excel file is empty');
          }
          
          const headers = jsonData[0] as string[];
          const rows = jsonData.slice(1).filter(row => 
            Array.isArray(row) && row.some(cell => cell !== null && cell !== undefined && cell !== '')
          );
          
          // Convert rows to objects
          const processedData = rows.map((row: any[], index) => {
            const obj: any = {};
            headers.forEach((header, colIndex) => {
              obj[header] = row[colIndex] || null;
            });
            obj._rowNumber = index + 2; // +2 because we start from row 2 (after header)
            return obj;
          });
          
          resolve({
            headers,
            data: processedData,
            totalRows: processedData.length,
            validationErrors: []
          });
        } catch (error) {
          reject(new Error(`Failed to parse Excel file: ${error instanceof Error ? error.message : 'Unknown error'}`));
        }
      };
      
      reader.onerror = () => {
        reject(new Error('Failed to read file'));
      };
      
      reader.readAsArrayBuffer(file);
    });
  }

  /**
   * Validate parsed data against expected columns
   */
  static validateData(data: any[], columnMapping: ColumnMapping): ValidationError[] {
    const errors: ValidationError[] = [];
    
    data.forEach((row, index) => {
      // Check required fields
      DISTRIBUTION_COLUMNS.forEach(col => {
        if (col.required) {
          const mappedColumn = Object.keys(columnMapping).find(key => columnMapping[key] === col.key);
          if (!mappedColumn) {
            errors.push({
              row: row._rowNumber || index + 1,
              column: col.key,
              value: null,
              message: `Required column "${col.label}" is not mapped`
            });
            return;
          }
          
          const value = row[mappedColumn];
          if (value === null || value === undefined || value === '') {
            errors.push({
              row: row._rowNumber || index + 1,
              column: mappedColumn,
              value,
              message: `Required field "${col.label}" is empty`
            });
          }
        }
      });
      
      // Type validation
      Object.keys(columnMapping).forEach(excelCol => {
        const fieldKey = columnMapping[excelCol];
        const column = DISTRIBUTION_COLUMNS.find(c => c.key === fieldKey);
        const value = row[excelCol];
        
        if (column && value !== null && value !== undefined && value !== '') {
          switch (column.type) {
            case 'number':
              if (isNaN(Number(value))) {
                errors.push({
                  row: row._rowNumber || index + 1,
                  column: excelCol,
                  value,
                  message: `"${column.label}" must be a number`
                });
              }
              break;
            case 'email':
              if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value))) {
                errors.push({
                  row: row._rowNumber || index + 1,
                  column: excelCol,
                  value,
                  message: `"${column.label}" must be a valid email address`
                });
              }
              break;
            case 'date':
              if (isNaN(Date.parse(String(value)))) {
                errors.push({
                  row: row._rowNumber || index + 1,
                  column: excelCol,
                  value,
                  message: `"${column.label}" must be a valid date`
                });
              }
              break;
          }
        }
      });
    });
    
    return errors;
  }

  /**
   * Transform data using column mapping
   */
  static transformData(data: any[], columnMapping: ColumnMapping): any[] {
    return data.map(row => {
      const transformed: any = {};
      
      Object.keys(columnMapping).forEach(excelCol => {
        const fieldKey = columnMapping[excelCol];
        const column = DISTRIBUTION_COLUMNS.find(c => c.key === fieldKey);
        let value = row[excelCol];
        
        if (value !== null && value !== undefined && value !== '') {
          // Type conversion
          if (column?.type === 'number') {
            value = Number(value);
          } else if (column?.type === 'date' && value) {
            // Handle Excel date formats
            if (typeof value === 'number') {
              // Excel date serial number
              const excelEpoch = new Date(1900, 0, 1);
              const date = new Date(excelEpoch.getTime() + (value - 2) * 24 * 60 * 60 * 1000);
              value = date.toISOString().split('T')[0];
            } else {
              value = new Date(value).toISOString().split('T')[0];
            }
          }
        }
        
        transformed[fieldKey] = value || null;
      });
      
      return transformed;
    });
  }

  /**
   * Generate Excel template for download
   */
  static generateTemplate(): ArrayBuffer {
    const template = [
      DISTRIBUTION_COLUMNS.map(col => col.label),
      DISTRIBUTION_COLUMNS.map(col => col.example || '')
    ];
    
    const worksheet = XLSX.utils.aoa_to_sheet(template);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Investor Distributions');
    
    return XLSX.write(workbook, { type: 'array', bookType: 'xlsx' });
  }

  /**
   * Export calculation results to Excel
   */
  static exportCalculations(calculations: any[], metadata?: any): ArrayBuffer {
    const exportData = calculations.map(calc => ({
      'Investor Name': calc.entity_name,
      'Commission Type': calc.commission_type,
      'Distribution Amount': calc.base_amount,
      'Applied Rate': `${(calc.applied_rate * 100).toFixed(3)}%`,
      'Gross Commission': calc.gross_commission,
      'VAT Rate': `${(calc.vat_rate * 100).toFixed(1)}%`,
      'VAT Amount': calc.vat_amount,
      'Net Commission': calc.net_commission,
      'Calculation Method': calc.calculation_method,
      'Status': calc.status,
      'Calculated At': new Date(calc.created_at).toLocaleDateString()
    }));
    
    const worksheet = XLSX.utils.json_to_sheet(exportData);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Commission Calculations');
    
    // Add metadata sheet if provided
    if (metadata) {
      const metaData = [
        ['Report Generated', new Date().toLocaleString()],
        ['Total Calculations', calculations.length],
        ['Total Gross Fees', metadata.totalGross || 0],
        ['Total VAT', metadata.totalVat || 0],
        ['Total Net Payable', metadata.totalNet || 0]
      ];
      const metaSheet = XLSX.utils.aoa_to_sheet(metaData);
      XLSX.utils.book_append_sheet(workbook, metaSheet, 'Summary');
    }
    
    return XLSX.write(workbook, { type: 'array', bookType: 'xlsx' });
  }
}