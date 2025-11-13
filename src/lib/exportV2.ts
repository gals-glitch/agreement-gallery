import * as XLSX from 'xlsx';
import { format } from 'date-fns';

/**
 * Export v2: Finance-ready XLSX with FUND vs DEAL scope breakdown
 * 
 * Generates 4 sheets:
 * 1. Summary - Run metadata + totals with Fund vs Deal breakdown
 * 2. Fee Lines - Detailed fee lines with scope, deal_id, deal_code, deal_name
 * 3. Credits Applied - Credit applications with post-apply balances
 * 4. Config Snapshot - Fund VI tracks configuration used
 */

export interface ExportRunData {
  run_id: string;
  run_name: string;
  period_start: string;
  period_end: string;
  created_at: string;
  status: string;
  run_hash: string;
  config_version: string;
}

export interface ExportFeeLine {
  contribution_id: string;
  entity_type: string;
  entity_name: string;
  investor_name: string;
  fund_name: string;
  scope: 'FUND' | 'DEAL';
  deal_id?: string | null;
  deal_code?: string | null;
  deal_name?: string | null;
  distribution_amount: number;
  base_amount: number;
  applied_rate: number;
  fee_gross: number;
  vat_rate: number;
  vat_amount: number;
  fee_net: number;
  total_payable: number;
  calculation_method: string;
  notes?: string;
}

export interface ExportCreditApplication {
  credit_id: string;
  credit_type: string;
  credit_scope: 'FUND' | 'DEAL';
  credit_deal_id?: string | null;
  investor_name: string;
  fund_name?: string;
  fee_line_id: string;
  fee_line_entity: string;
  amount_applied: number;
  remaining_balance: number;
  date_applied: string;
}

export interface ExportFundTrack {
  track_key: string;
  min_raised: number;
  max_raised: number | null;
  upfront_rate_bps: number;
  deferred_rate_bps: number;
  deferred_offset_months: number;
  config_version: string;
}

export interface ExportData {
  run: ExportRunData;
  totals: {
    total_gross: number;
    total_vat: number;
    total_net: number;
  };
  scope_breakdown: {
    FUND: { gross: number; vat: number; net: number; count: number };
    DEAL: { gross: number; vat: number; net: number; count: number };
  };
  fee_lines: ExportFeeLine[];
  credits_applied: ExportCreditApplication[];
  fund_tracks: ExportFundTrack[];
}

export class ExportV2Generator {
  /**
   * Generate XLSX workbook from run data
   */
  static generateWorkbook(data: ExportData): XLSX.WorkBook {
    const wb = XLSX.utils.book_new();

    // Sheet 1: Summary
    const summarySheet = this.generateSummarySheet(data);
    XLSX.utils.book_append_sheet(wb, summarySheet, 'Summary');

    // Sheet 2: Fee Lines
    const feeLinesSheet = this.generateFeeLinesSheet(data.fee_lines);
    XLSX.utils.book_append_sheet(wb, feeLinesSheet, 'Fee Lines');

    // Sheet 3: Credits Applied
    const creditsSheet = this.generateCreditsSheet(data.credits_applied);
    XLSX.utils.book_append_sheet(wb, creditsSheet, 'Credits Applied');

    // Sheet 4: Config Snapshot
    const configSheet = this.generateConfigSheet(data.fund_tracks);
    XLSX.utils.book_append_sheet(wb, configSheet, 'Config Snapshot');

    return wb;
  }

  /**
   * Sheet 1: Summary with run metadata and Fund vs Deal totals
   */
  private static generateSummarySheet(data: ExportData): XLSX.WorkSheet {
    const rows: any[] = [];

    // Run metadata
    rows.push(['Run Information', '']);
    rows.push(['Run ID', data.run.run_id]);
    rows.push(['Run Name', data.run.run_name]);
    rows.push(['Period Start', data.run.period_start]);
    rows.push(['Period End', data.run.period_end]);
    rows.push(['Status', data.run.status]);
    rows.push(['Created At', format(new Date(data.run.created_at), 'yyyy-MM-dd HH:mm:ss')]);
    rows.push(['Config Version', data.run.config_version]);
    rows.push(['Run Hash', data.run.run_hash]);
    rows.push([]);

    // Overall totals
    rows.push(['Overall Totals', '']);
    rows.push(['Total Gross Fees', data.totals.total_gross]);
    rows.push(['Total VAT', data.totals.total_vat]);
    rows.push(['Total Net Payable', data.totals.total_net]);
    rows.push([]);

    // Fund vs Deal breakdown
    rows.push(['Scope Breakdown', '', '', '']);
    rows.push(['Scope', 'Gross Fees', 'VAT', 'Net Payable', 'Line Count']);
    rows.push([
      'FUND',
      data.scope_breakdown.FUND.gross,
      data.scope_breakdown.FUND.vat,
      data.scope_breakdown.FUND.net,
      data.scope_breakdown.FUND.count,
    ]);
    rows.push([
      'DEAL',
      data.scope_breakdown.DEAL.gross,
      data.scope_breakdown.DEAL.vat,
      data.scope_breakdown.DEAL.net,
      data.scope_breakdown.DEAL.count,
    ]);

    const ws = XLSX.utils.aoa_to_sheet(rows);

    // Set column widths
    ws['!cols'] = [
      { wch: 20 },
      { wch: 20 },
      { wch: 15 },
      { wch: 15 },
      { wch: 12 },
    ];

    return ws;
  }

  /**
   * Sheet 2: Fee Lines with scope and deal information
   */
  private static generateFeeLinesSheet(feeLines: ExportFeeLine[]): XLSX.WorkSheet {
    const data = feeLines.map(line => ({
      'Entity Type': line.entity_type,
      'Entity Name': line.entity_name,
      'Investor': line.investor_name,
      'Fund': line.fund_name,
      'Scope': line.scope,
      'Deal ID': line.deal_id || '',
      'Deal Code': line.deal_code || '',
      'Deal Name': line.deal_name || '',
      'Distribution Amount': line.distribution_amount,
      'Base Amount': line.base_amount,
      'Applied Rate (%)': line.applied_rate,
      'Gross Fee': line.fee_gross,
      'VAT Rate (%)': line.vat_rate,
      'VAT Amount': line.vat_amount,
      'Net Fee': line.fee_net,
      'Total Payable': line.total_payable,
      'Calculation Method': line.calculation_method,
      'Notes': line.notes || '',
    }));

    const ws = XLSX.utils.json_to_sheet(data);

    // Set column widths
    ws['!cols'] = [
      { wch: 15 }, // Entity Type
      { wch: 25 }, // Entity Name
      { wch: 25 }, // Investor
      { wch: 15 }, // Fund
      { wch: 8 },  // Scope
      { wch: 10 }, // Deal ID
      { wch: 12 }, // Deal Code
      { wch: 20 }, // Deal Name
      { wch: 15 }, // Distribution Amount
      { wch: 15 }, // Base Amount
      { wch: 12 }, // Applied Rate
      { wch: 15 }, // Gross Fee
      { wch: 12 }, // VAT Rate
      { wch: 15 }, // VAT Amount
      { wch: 15 }, // Net Fee
      { wch: 15 }, // Total Payable
      { wch: 18 }, // Calculation Method
      { wch: 30 }, // Notes
    ];

    return ws;
  }

  /**
   * Sheet 3: Credits Applied with scope information
   */
  private static generateCreditsSheet(credits: ExportCreditApplication[]): XLSX.WorkSheet {
    const data = credits.map(credit => ({
      'Credit ID': credit.credit_id,
      'Credit Type': credit.credit_type,
      'Credit Scope': credit.credit_scope,
      'Credit Deal ID': credit.credit_deal_id || '',
      'Investor': credit.investor_name,
      'Fund': credit.fund_name || '',
      'Applied To Fee Line': credit.fee_line_id,
      'Fee Line Entity': credit.fee_line_entity,
      'Amount Applied': credit.amount_applied,
      'Remaining Balance': credit.remaining_balance,
      'Date Applied': credit.date_applied,
    }));

    const ws = XLSX.utils.json_to_sheet(data);

    // Set column widths
    ws['!cols'] = [
      { wch: 12 }, // Credit ID
      { wch: 15 }, // Credit Type
      { wch: 12 }, // Credit Scope
      { wch: 15 }, // Credit Deal ID
      { wch: 25 }, // Investor
      { wch: 15 }, // Fund
      { wch: 15 }, // Applied To Fee Line
      { wch: 20 }, // Fee Line Entity
      { wch: 15 }, // Amount Applied
      { wch: 15 }, // Remaining Balance
      { wch: 15 }, // Date Applied
    ];

    return ws;
  }

  /**
   * Sheet 4: Config Snapshot - Fund VI tracks used
   */
  private static generateConfigSheet(tracks: ExportFundTrack[]): XLSX.WorkSheet {
    const data = tracks.map(track => ({
      'Track Key': track.track_key,
      'Min Raised': track.min_raised,
      'Max Raised': track.max_raised || 'No limit',
      'Upfront Rate (bps)': track.upfront_rate_bps,
      'Deferred Rate (bps)': track.deferred_rate_bps,
      'Deferred Offset (months)': track.deferred_offset_months,
      'Config Version': track.config_version,
    }));

    const ws = XLSX.utils.json_to_sheet(data);

    // Set column widths
    ws['!cols'] = [
      { wch: 12 }, // Track Key
      { wch: 15 }, // Min Raised
      { wch: 15 }, // Max Raised
      { wch: 18 }, // Upfront Rate
      { wch: 18 }, // Deferred Rate
      { wch: 22 }, // Deferred Offset
      { wch: 15 }, // Config Version
    ];

    return ws;
  }

  /**
   * Generate and download XLSX file
   */
  static downloadWorkbook(wb: XLSX.WorkBook, filename: string): void {
    XLSX.writeFile(wb, filename);
  }

  /**
   * Generate filename for export
   */
  static generateFilename(runName: string, runId: string): string {
    const timestamp = format(new Date(), 'yyyyMMdd-HHmmss');
    const safeName = runName.replace(/[^a-zA-Z0-9-]/g, '_');
    return `FeeRun_${safeName}_${runId.substring(0, 8)}_${timestamp}.xlsx`;
  }
}
