import type { KeyboardEvent } from "react";

import type { Investor } from "../types";

interface InvestorPickerProps {
  query: string;
  investors: Investor[];
  isSearching: boolean;
  onQueryChange: (value: string) => void;
  onSelect: (investor: Investor) => void;
  selectedInvestor: Investor | null;
  onClear: () => void;
  disabled?: boolean;
  error?: string | null;
}

const getInitials = (value: string) =>
  value
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((chunk) => chunk[0]?.toUpperCase())
    .join("")
    .padEnd(2, "•");

const InvestorPicker = ({
  query,
  investors,
  isSearching,
  onQueryChange,
  onSelect,
  selectedInvestor,
  onClear,
  disabled,
  error,
}: InvestorPickerProps) => {
  const topMatch = investors[0];

  const handleKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === "Enter" && topMatch) {
      event.preventDefault();
      onSelect(topMatch);
    }
  };

  return (
    <section className="panel picker">
      <label htmlFor="investor-search" className="panel-label">
        Search investor
      </label>
      <div className="input-wrapper">
        <input
          id="investor-search"
          type="search"
          placeholder="Type a name or email"
          autoComplete="off"
          value={query}
          onChange={(event) => onQueryChange(event.target.value)}
          onKeyDown={handleKeyDown}
          disabled={disabled}
          aria-autocomplete="list"
          aria-controls="investor-results"
          aria-expanded={investors.length > 0}
        />
        {isSearching && <span className="input-hint">Searching…</span>}
      </div>

      {investors.length > 0 && (
        <ul id="investor-results" role="listbox" className="typeahead">
          {investors.map((investor) => (
            <li key={investor.id}>
              <button
                type="button"
                role="option"
                onClick={() => onSelect(investor)}
                aria-label={`${investor.name} • ${investor.email}`}
              >
                <span>{investor.name}</span>
                <small>• {investor.email}</small>
              </button>
            </li>
          ))}
        </ul>
      )}

      {selectedInvestor ? (
        <div className="selected-investor" aria-live="polite">
          <div className="avatar" aria-hidden="true">
            {getInitials(selectedInvestor.name)}
          </div>
          <div className="details">
            <p className="name">{selectedInvestor.name}</p>
            <p className="email">{selectedInvestor.email}</p>
          </div>
          <button type="button" className="btn link" onClick={onClear}>
            Change
          </button>
        </div>
      ) : error ? (
        <p className="error-text" role="status">
          {error} • tap Enter to retry.
        </p>
      ) : (
        <p className="helper-text">Need at least 2 characters to search.</p>
      )}
    </section>
  );
};

export default InvestorPicker;
