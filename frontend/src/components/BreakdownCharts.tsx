import { memo, useMemo, useState } from "react";
import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";

import { formatCurrency, formatPercent } from "../utils/format";
import { exportToCsv } from "../utils/export";

const CHART_COLORS = ["#fde047", "#facc15", "#f97316", "#fb7185", "#c084fc", "#818cf8", "#38bdf8", "#34d399", "#4ade80"];

export interface BreakdownRow {
  name: string;
  value: number;
  contribution: number;
  distribution: number;
  positions: number;
  [key: string]: string | number;
}

interface BreakdownChartsProps {
  sectorRows: BreakdownRow[];
  countryRows: BreakdownRow[];
  baseCurrency: string;
  isLoading: boolean;
  onSliceClick?: (type: "sector" | "country", row: BreakdownRow) => void;
}

const TooltipContent = ({ active, payload, currency }: { active?: boolean; payload?: any[]; currency: string }) => {
  if (!active || !payload?.length) {
    return null;
  }
  const { name, value } = payload[0];
  return (
    <div className="chart-tooltip">
      <strong>{name}</strong>
      <span>{formatCurrency(value, currency)}</span>
    </div>
  );
};

const BreakdownSection = ({
  title,
  rows,
  baseCurrency,
  isLoading,
  onSliceClick,
  kind,
}: {
  title: string;
  rows: BreakdownRow[];
  baseCurrency: string;
  isLoading: boolean;
  onSliceClick?: (type: "sector" | "country", row: BreakdownRow) => void;
  kind: "sector" | "country";
}) => {
  const [activeSlice, setActiveSlice] = useState<number | null>(null);
  const totals = useMemo(() => {
    return rows.reduce(
      (acc, row) => {
        acc.value += row.value;
        acc.contribution += row.contribution;
        acc.distribution += row.distribution;
        acc.positions += row.positions;
        return acc;
      },
      { value: 0, contribution: 0, distribution: 0, positions: 0 },
    );
  }, [rows]);

  const percentFor = (value: number) => (totals.value === 0 ? 0 : (value / totals.value) * 100);

  const handleExport = () => {
    const csvRows = [
      ["Segment", "Market Value", "% Portfolio", "Contributions", "Distributions", "Positions"],
      ...rows.map((row) => [
        row.name,
        formatCurrency(row.value, baseCurrency),
        formatPercent(percentFor(row.value), 1),
        formatCurrency(row.contribution, baseCurrency),
        formatCurrency(row.distribution, baseCurrency),
        row.positions,
      ]),
      [
        "Total",
        formatCurrency(totals.value, baseCurrency),
        "100.0%",
        formatCurrency(totals.contribution, baseCurrency),
        formatCurrency(totals.distribution, baseCurrency),
        totals.positions,
      ],
    ];
    exportToCsv(`${title.toLowerCase().replace(/\s+/g, "-")}-breakdown.csv`, csvRows);
  };

  return (
    <div className="panel breakdown-panel">
      <div className="panel-header">
        <h3>{title}</h3>
        <button type="button" className="btn ghost" onClick={handleExport} disabled={rows.length === 0 || isLoading}>
          Export CSV
        </button>
      </div>
      {isLoading ? (
        <div className="chart-skeleton" aria-busy="true" aria-label="Loading chart" />
      ) : rows.length === 0 ? (
        <p className="placeholder">No data available.</p>
      ) : (
        <div className="pie-wrapper">
          <ResponsiveContainer width="100%" height={240}>
            <PieChart>
              <Pie
                data={rows}
                dataKey="value"
                nameKey="name"
                innerRadius={60}
                outerRadius={100}
                onMouseEnter={(_, index) => setActiveSlice(index)}
                onMouseLeave={() => setActiveSlice(null)}
                onClick={(_payload, index) => {
                  if (onSliceClick && index != null && rows[index]) {
                    onSliceClick(kind, rows[index]);
                  }
                }}
              >
                {rows.map((_entry, index) => (
                  <Cell
                    key={`${title}-${index}`}
                    fill={CHART_COLORS[index % CHART_COLORS.length]}
                    fillOpacity={activeSlice === null || activeSlice === index ? 1 : 0.35}
                  />
                ))}
              </Pie>
              <Tooltip content={<TooltipContent currency={baseCurrency} />} />
            </PieChart>
          </ResponsiveContainer>
          <ul className="legend">
            {rows.map((row, index) => (
              <li
                key={row.name}
                className={activeSlice === index ? "active" : ""}
                onMouseEnter={() => setActiveSlice(index)}
                onMouseLeave={() => setActiveSlice(null)}
                title={row.name}
              >
                <span className="dot" style={{ background: CHART_COLORS[index % CHART_COLORS.length] }} />
                <span className="name" aria-hidden="true">
                  {row.name}
                </span>
                <span className="value">{formatCurrency(row.value, baseCurrency)}</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      {!isLoading && rows.length > 0 && (
        <div className="table-wrapper">
          <table>
            <thead>
              <tr>
                <th align="left">Segment</th>
                <th align="right">Market value</th>
                <th align="right">% portfolio</th>
                <th align="right">Contributions</th>
                <th align="right">Distributions</th>
                <th align="right">Positions</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={`${title}-${row.name}`}>
                  <td title={row.name} className="truncate">
                    {row.name}
                  </td>
                  <td align="right">{formatCurrency(row.value, baseCurrency)}</td>
                  <td align="right">{formatPercent(percentFor(row.value), 1)}</td>
                  <td align="right">{formatCurrency(row.contribution, baseCurrency)}</td>
                  <td align="right">{formatCurrency(row.distribution, baseCurrency)}</td>
                  <td align="right">{row.positions}</td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <td>Total</td>
                <td align="right">{formatCurrency(totals.value, baseCurrency)}</td>
                <td align="right">100.0%</td>
                <td align="right">{formatCurrency(totals.contribution, baseCurrency)}</td>
                <td align="right">{formatCurrency(totals.distribution, baseCurrency)}</td>
                <td align="right">{totals.positions}</td>
              </tr>
            </tfoot>
          </table>
        </div>
      )}
    </div>
  );
};

const BreakdownCharts = ({ sectorRows, countryRows, baseCurrency, isLoading, onSliceClick }: BreakdownChartsProps) => (
  <section className="charts-grid">
    <BreakdownSection
      title="Sector breakdown"
      rows={sectorRows}
      baseCurrency={baseCurrency}
      isLoading={isLoading}
      onSliceClick={onSliceClick}
      kind="sector"
    />
    <BreakdownSection
      title="Country breakdown"
      rows={countryRows}
      baseCurrency={baseCurrency}
      isLoading={isLoading}
      onSliceClick={onSliceClick}
      kind="country"
    />
  </section>
);

export default memo(BreakdownCharts);
