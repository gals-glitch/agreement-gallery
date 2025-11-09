interface HeaderProps {
  investorName?: string;
  baseCurrency?: string;
  onExport: () => void;
  onPrint: () => void;
  disabled: boolean;
  isExporting: boolean;
  isPrinting: boolean;
}

const Header = ({
  investorName,
  baseCurrency = "USD",
  onExport,
  onPrint,
  disabled,
  isExporting,
  isPrinting,
}: HeaderProps) => {
  const caption = investorName ? `${investorName} • ${baseCurrency}` : "Select an investor to get started";

  return (
    <header className="page-header">
      <div>
        <p className="eyebrow">IR command center</p>
        <h1>Investor Performance Explorer</h1>
        <p className="caption">{caption}</p>
      </div>
      <div className="header-actions">
        <button className="btn secondary" type="button" onClick={onPrint} disabled={disabled || isPrinting}>
          {isPrinting ? (
            <>
              <span className="spinner" aria-hidden="true" /> Preparing…
            </>
          ) : (
            "Print"
          )}
        </button>
        <button className="btn primary" type="button" onClick={onExport} disabled={disabled || isExporting}>
          {isExporting ? (
            <>
              <span className="spinner" aria-hidden="true" /> Generating…
            </>
          ) : (
            "Export PDF"
          )}
        </button>
      </div>
    </header>
  );
};

export default Header;

