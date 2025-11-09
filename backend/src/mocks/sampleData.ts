import type {
  AccountContactMap,
  Asset,
  Cashflow,
  Commitment,
  Contact,
  FinancialRecord,
  Fund,
} from "../types/erp";

interface MockData {
  contacts: Contact[];
  accountMappings: AccountContactMap[];
  commitments: Commitment[];
  cashflows: Cashflow[];
  financials: FinancialRecord[];
  funds: Fund[];
  assets: Asset[];
}

const MOCK_DATA: MockData = {
  contacts: [
    {
      contact_id: 1,
      full_name: "Dana Levi",
      reporting_email: "dana.levi@example.com",
    },
    {
      contact_id: 2,
      full_name: "Amit Cohen",
      reporting_email: "amit.cohen@example.com",
    },
  ],
  accountMappings: [
    {
      contact_id: 1,
      contact_name: "Dana Levi",
      account_id: 11,
      account_name: "Dana Holdings LLC",
      fund_id: 101,
      fund_name: "Buligo Industrial Fund",
      relationship: "Primary",
      is_primary: "true",
    },
    {
      contact_id: 1,
      contact_name: "Dana Levi",
      account_id: 11,
      account_name: "Dana Holdings LLC",
      fund_id: 102,
      fund_name: "Sunset Multifamily",
      relationship: "Primary",
      is_primary: "true",
    },
    {
      contact_id: 2,
      contact_name: "Amit Cohen",
      account_id: 15,
      account_name: "Cohen Family LP",
      fund_id: 102,
      fund_name: "Sunset Multifamily",
      relationship: "Primary",
      is_primary: "true",
    },
  ],
  commitments: [
    {
      fund_id: 101,
      account_id: 11,
      commitment_amount: 150000,
      commitment_date: "2022-01-15",
      currency: "USD",
    },
    {
      fund_id: 102,
      account_id: 11,
      commitment_amount: 90000,
      commitment_date: "2023-05-10",
      currency: "USD",
    },
    {
      fund_id: 102,
      account_id: 15,
      commitment_amount: 50000,
      commitment_date: "2023-05-10",
      currency: "USD",
    },
  ],
  cashflows: [
    {
      fund_id: 101,
      account_id: 11,
      transaction_date: "2022-02-01",
      transaction_amount: -75000,
      transaction_amount_usd: -75000,
      transaction_type: "contribution",
    },
    {
      fund_id: 101,
      account_id: 11,
      transaction_date: "2022-08-01",
      transaction_amount: -75000,
      transaction_amount_usd: -75000,
      transaction_type: "capital_call",
    },
    {
      fund_id: 101,
      account_id: 11,
      transaction_date: "2024-06-30",
      transaction_amount: 12000,
      transaction_amount_usd: 12000,
      transaction_type: "distribution",
    },
    {
      fund_id: 102,
      account_id: 11,
      transaction_date: "2023-06-01",
      transaction_amount: -45000,
      transaction_amount_usd: -45000,
      transaction_type: "contribution",
    },
    {
      fund_id: 102,
      account_id: 11,
      transaction_date: "2024-03-01",
      transaction_amount: -45000,
      transaction_amount_usd: -45000,
      transaction_type: "contribution",
    },
    {
      fund_id: 102,
      account_id: 11,
      transaction_date: "2024-09-30",
      transaction_amount: 8000,
      transaction_amount_usd: 8000,
      transaction_type: "distribution",
    },
    {
      fund_id: 102,
      account_id: 15,
      transaction_date: "2023-06-01",
      transaction_amount: -25000,
      transaction_amount_usd: -25000,
      transaction_type: "contribution",
    },
  ],
  financials: [
    {
      fund_id: 101,
      fund_name: "Buligo Industrial Fund",
      report_date: "2024-09-30",
      financialtype: "Quarterly",
      financialMetrics: {
        nav: 162000,
        noi_actual: 125000,
        noi_budget: 120000,
      },
    },
    {
      fund_id: 102,
      fund_name: "Sunset Multifamily",
      report_date: "2024-09-30",
      financialtype: "Quarterly",
      financialMetrics: {
        nav: 98000,
        noi_actual: 68000,
        noi_budget: 70000,
      },
    },
  ],
  funds: [
    {
      fund_id: 101,
      fundname: "Buligo Industrial Fund",
      shortname: "BIF",
      market_value: 162000,
      strategy: "Industrial",
      sector: "Industrial",
      region: "US",
    },
    {
      fund_id: 102,
      fundname: "Sunset Multifamily",
      shortname: "SUNSET",
      market_value: 98000,
      strategy: "Residential",
      sector: "Multifamily",
      region: "US",
    },
  ],
  assets: [
    {
      asset_id: 201,
      asset_name: "1000 W Crosby",
      fund_id: 101,
      fund_name: "Buligo Industrial Fund",
      sector: "Industrial",
      country: "USA",
      region: "US",
    },
    {
      asset_id: 202,
      asset_name: "Sunset Park",
      fund_id: 102,
      fund_name: "Sunset Multifamily",
      sector: "Multifamily",
      country: "USA",
      region: "US",
    },
  ],
};

export const loadMockData = (): MockData => MOCK_DATA;

