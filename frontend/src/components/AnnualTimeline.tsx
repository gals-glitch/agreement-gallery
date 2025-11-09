import { memo } from "react";
import { Bar, CartesianGrid, ComposedChart, Legend, Line, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

import { formatCurrency } from "../utils/format";
import { exportToCsv } from "../utils/export";

export interface AnnualPoint {
  year: string;
  contributions: number;
  distributions: number;
  equity: number;
}

interface AnnualTimelineProps {
  data: AnnualPoint[];
  baseCurrency: string;
  isLoading: boolean;
}

const AnnualTooltip = ({
  active,
  payload,
  label,
  currency,
}: {
  active?: boolean;
  payload?: any[];
  label?: string;
  currency: string;
}) => {
  if (!active || !payload?.length) {
    return null;
  }

  const values = payload.reduce<Record<string, number>>((acc, entry) => {
    acc[entry.name] = entry.value;
    return acc;
  }, {});

  return (
    <div className="chart-tooltip">
      <strong>{label}</strong>
      <span>In: {formatCurrency(values["In (Contributions)"] ?? 0, currency)}</span>
      <span>Out: {formatCurrency(values["Out (Distributions)"] ?? 0, currency)}</span>
      <span>Equity: {formatCurrency(values.Equity ?? 0, currency)}</span>
    </div>
  );
};

const AnnualTimeline = ({ data, baseCurrency, isLoading }: AnnualTimelineProps) => {
  const handleExport = () => {
    const csvRows = [
      ["Year", "In (Contributions)", "Out (Distributions)", "Equity"],
      ...data.map((row) => [row.year, row.contributions, row.distributions, row.equity]),
    ];
    exportToCsv("annual-cashflows.csv", csvRows);
  };

  return (
    <section className="panel timeline-panel">
      <div className="panel-header">
        <h3>Cash flow & equity timeline</h3>
        <button type="button" className="btn ghost" onClick={handleExport} disabled={data.length === 0 || isLoading}>
          Export CSV
        </button>
      </div>
      {isLoading ? (
        <div className="chart-skeleton" aria-busy="true" aria-label="Loading chart" />
      ) : data.length === 0 ? (
        <p className="placeholder">No cashflows in selected range.</p>
      ) : (
        <ResponsiveContainer width="100%" height={360}>
          <ComposedChart data={data} syncId="timeline">
            <CartesianGrid stroke="#1e293b" opacity={0.4} vertical={false} />
            <XAxis dataKey="year" tick={{ fill: "#94a3b8" }} />
            <YAxis tickFormatter={(value) => formatCurrency(value, baseCurrency)} tick={{ fill: "#94a3b8" }} />
            <Tooltip content={<AnnualTooltip currency={baseCurrency} />} />
            <Legend />
            <Bar dataKey="contributions" name="In (Contributions)" stackId="cash" fill="#f97316" radius={[4, 4, 0, 0]} />
            <Bar dataKey="distributions" name="Out (Distributions)" stackId="cash" fill="#22d3ee" radius={[4, 4, 0, 0]} />
            <Line
              type="monotone"
              dataKey="equity"
              name="Equity"
              stroke="#c084fc"
              strokeWidth={3}
              dot={{ r: 2 }}
              activeDot={{ r: 4 }}
            />
          </ComposedChart>
        </ResponsiveContainer>
      )}
    </section>
  );
};

export default memo(AnnualTimeline);
