import type { TimeRangeOption } from "../constants/timeRanges";

interface TimeRangeTabsProps {
  ranges: TimeRangeOption[];
  activeRange: TimeRangeOption;
  onSelect: (range: TimeRangeOption) => void;
  customRange: { from: string; to: string };
  onCustomChange: (range: { from: string; to: string }) => void;
  onApplyCustom: () => void;
  disabled?: boolean;
  isLoading?: boolean;
}

const TimeRangeTabs = ({
  ranges,
  activeRange,
  onSelect,
  customRange,
  onCustomChange,
  onApplyCustom,
  disabled,
  isLoading,
}: TimeRangeTabsProps) => {
  const isCustom = activeRange.label === "Custom";

  return (
    <section className="panel range-panel">
      <p className="panel-label">Time range</p>
      <div className="tablist" role="tablist" aria-label="Time ranges">
        {ranges.map((range) => (
          <button
            key={range.label}
            type="button"
            role="tab"
            aria-selected={activeRange.label === range.label}
            className={`pill ${activeRange.label === range.label ? "active" : ""}`}
            onClick={() => onSelect(range)}
            disabled={disabled}
          >
            {range.label}
          </button>
        ))}
      </div>

      {isCustom && (
        <div className="custom-range">
          <label>
            From
            <input
              type="date"
              value={customRange.from}
              onChange={(event) => onCustomChange({ ...customRange, from: event.target.value })}
              disabled={disabled}
            />
          </label>
          <label>
            To
            <input
              type="date"
              value={customRange.to}
              onChange={(event) => onCustomChange({ ...customRange, to: event.target.value })}
              disabled={disabled}
            />
          </label>
          <button type="button" className="btn secondary" onClick={onApplyCustom} disabled={disabled || isLoading}>
            Apply
          </button>
        </div>
      )}
    </section>
  );
};

export default TimeRangeTabs;

