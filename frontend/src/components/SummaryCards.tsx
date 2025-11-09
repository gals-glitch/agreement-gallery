interface SummaryMetric {
  key: string;
  label: string;
  value: string;
  delta?: string | null;
  tooltip?: string;
}

interface SummaryCardsProps {
  metrics: SummaryMetric[];
  isLoading: boolean;
}

const SummaryCards = ({ metrics, isLoading }: SummaryCardsProps) => {
  const placeholders = Array.from({ length: 4 });

  if (isLoading) {
    return (
      <section className="summary-cards" aria-live="polite" aria-busy="true">
        {placeholders.map((_, index) => (
          <div key={`skeleton-${index}`} className="metric-card skeleton">
            <span className="label" />
            <strong />
            <span className="delta" />
          </div>
        ))}
      </section>
    );
  }

  return (
    <section className="summary-cards" aria-live="polite">
      {metrics.map((metric) => {
        const isPositive = metric.delta?.startsWith("▲");
        return (
          <div key={metric.key} className="metric-card">
            <div className="label-row">
              <span className="label">
                {metric.label}
                {metric.tooltip && <span className="tooltip-icon" title={metric.tooltip} aria-label={metric.tooltip}>?</span>}
              </span>
            </div>
            <strong>{metric.value}</strong>
            {metric.delta && (
              <span className={`delta ${isPositive ? "positive" : "negative"}`}>{metric.delta}</span>
            )}
          </div>
        );
      })}
    </section>
  );
};

export default SummaryCards;
