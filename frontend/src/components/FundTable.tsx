import type { CSSProperties } from "react";
import { FixedSizeList } from "react-window";
import type { ListChildComponentProps } from "react-window";

import type { PerFundKpi } from "../types";
import { formatCurrency, formatIsoDate } from "../utils/format";
import { exportToCsv } from "../utils/export";

type NetView = "invested" | "toInvestor";

interface FundTableProps {
  funds: PerFundKpi[];
  baseCurrency: string;
  isLoading: boolean;
  totals: {
    contributions: number;
    distributions: number;
  };
  netView: NetView;
}

const FundRow = ({
  fund,
  baseCurrency,
  netView,
  style,
}: {
  fund: PerFundKpi;
  baseCurrency: string;
  netView: NetView;
  style?: CSSProperties;
}) => {
  const currency = fund.currency ?? baseCurrency;
  const netInvested = fund.contributions - fund.distributions;
  const netToInvestor = fund.netCash ?? fund.distributions - fund.contributions;
  const netValue = netView === "invested" ? netInvested : netToInvestor;

  return (
    <div className="table-row" role="row" style={style}>
      <div className="cell fund" role="cell" title={fund.fundName ?? `Fund ${fund.fundId}`}>
        <span className="name">{fund.fundName ?? `Fund ${fund.fundId}`}</span>
      </div>
      <div className="cell right" role="cell">
        {formatCurrency(fund.contributions, currency)}
      </div>
      <div className="cell right" role="cell">
        {formatCurrency(fund.distributions, currency)}
      </div>
      <div className="cell right" role="cell">
        {formatCurrency(netValue, currency)}
      </div>
      <div className="cell right" role="cell">
        {fund.firstFlowDate ? formatIsoDate(fund.firstFlowDate) : "—"}
      </div>
      <div className="cell right" role="cell">
        {fund.lastFlowDate ? formatIsoDate(fund.lastFlowDate) : "—"}
      </div>
    </div>
  );
};

interface RowData {
  funds: PerFundKpi[];
  baseCurrency: string;
  netView: NetView;
}

const VirtualRow = ({ index, style, data }: ListChildComponentProps<RowData>) => (
  <FundRow fund={data.funds[index]} baseCurrency={data.baseCurrency} netView={data.netView} style={style} />
);

const FundTable = ({ funds, baseCurrency, isLoading, totals, netView }: FundTableProps) => {
  const useVirtual = funds.length > 50;
  const listHeight = Math.min(480, Math.max(6, funds.length) * 56);
  const netHeader = netView === "invested" ? "Net Invested" : "Net to investor";

  const handleExport = () => {
    const csvRows = [
      ["Fund", "Contributions", "Distributions", netHeader, "First Flow", "Most Recent Flow"],
      ...funds.map((fund) => {
        const currency = fund.currency ?? baseCurrency;
        const netInvested = fund.contributions - fund.distributions;
        const netToInvestor = fund.netCash ?? fund.distributions - fund.contributions;
        const netCurrency = netView === "invested" ? netInvested : netToInvestor;
        return [
          fund.fundName ?? `Fund ${fund.fundId}`,
          formatCurrency(fund.contributions, currency),
          formatCurrency(fund.distributions, currency),
          formatCurrency(netCurrency, currency),
          fund.firstFlowDate ?? "—",
          fund.lastFlowDate ?? "—",
        ];
      }),
    ];
    exportToCsv("fund-metrics.csv", csvRows);
  };

  if (isLoading) {
    return (
      <section className="panel table-panel">
        <div className="panel-header">
          <h3>Fund metrics</h3>
          <button className="btn ghost" type="button" disabled>
            Export CSV
          </button>
        </div>
        <div className="table-skeleton" aria-busy="true" aria-label="Loading table" />
      </section>
    );
  }

  if (funds.length === 0) {
    return (
      <section className="panel table-panel">
        <div className="panel-header">
          <h3>Fund metrics</h3>
          <button className="btn ghost" type="button" disabled>
            Export CSV
          </button>
        </div>
        <p className="placeholder">No investments found for this range.</p>
      </section>
    );
  }

  const totalsNetInvested = totals.contributions - totals.distributions;
  const totalsNetToInvestor = totals.distributions - totals.contributions;
  const totalsNetLabelValue = netView === "invested" ? totalsNetInvested : totalsNetToInvestor;

  return (
    <section className="panel table-panel">
      <div className="panel-header">
        <h3>Fund metrics</h3>
        <button className="btn ghost" type="button" onClick={handleExport}>
          Export CSV
        </button>
      </div>
      <div className="virtual-table" role="table" aria-label="Per fund KPIs">
        <div className="table-row header" role="row">
          <div className="cell fund" role="columnheader">
            Fund
          </div>
          <div className="cell right" role="columnheader">
            Contributions
          </div>
          <div className="cell right" role="columnheader">
            Distributions
          </div>
          <div className="cell right" role="columnheader">
            {netHeader}
          </div>
          <div className="cell right" role="columnheader">
            First Flow
          </div>
          <div className="cell right" role="columnheader">
            Most Recent Flow
          </div>
        </div>
        <div className="table-body" role="rowgroup">
          {useVirtual ? (
            <FixedSizeList
              height={listHeight}
              itemCount={funds.length}
              itemSize={56}
              width="100%"
              itemData={{ funds, baseCurrency, netView }}
            >
              {VirtualRow}
            </FixedSizeList>
          ) : (
            funds.map((fund) => (
              <FundRow key={fund.fundId} fund={fund} baseCurrency={baseCurrency} netView={netView} />
            ))
          )}
        </div>
        <div className="table-row footer" role="row">
          <div className="cell fund" role="cell">
            Total
          </div>
          <div className="cell right" role="cell">
            {formatCurrency(totals.contributions, baseCurrency)}
          </div>
          <div className="cell right" role="cell">
            {formatCurrency(totals.distributions, baseCurrency)}
          </div>
          <div className="cell right" role="cell">
            {formatCurrency(totalsNetLabelValue, baseCurrency)}
          </div>
          <div className="cell right" role="cell">
            —
          </div>
          <div className="cell right" role="cell">
            —
          </div>
        </div>
      </div>
    </section>
  );
};

export default FundTable;
