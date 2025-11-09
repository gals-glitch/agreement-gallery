import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import html2canvas from "html2canvas";
import jsPDF from "jspdf";

import { fetchPortfolio, fetchSnapshot, searchInvestors } from "./api";
import AnnualTimeline from "./components/AnnualTimeline";
import BreakdownCharts, { type BreakdownRow } from "./components/BreakdownCharts";
import FundTable from "./components/FundTable";
import Header from "./components/Header";
import InvestorPicker from "./components/InvestorPicker";
import SummaryCards from "./components/SummaryCards";
import TimeRangeTabs from "./components/TimeRangeTabs";
import { quickRanges, type TimeRangeOption } from "./constants/timeRanges";
import { resolvePresetRange } from "./lib/dateRange";
import type { Investor, PortfolioSummary, SnapshotResponse, NetView } from "./types";
import { formatCurrency, formatDelta, formatIsoDate, formatNumber, formatPercent } from "./utils/format";
import "./App.css";
import "./styles/print.css";

type CustomRange = { from: string; to: string };
interface DiagnosticsFund {
  fundId: number;
  fundName: string;
  contributionsInRange?: number | null;
  distributionsInRange?: number | null;
  firstEverFlow?: string | null;
  lastEverFlow?: string | null;
}

interface InvestorDiagnostics {
  contact: {
    id: number;
    name: string;
    email: string;
  };
  accountCount: number;
  unionFundCount: number;
  sources: {
    fromMappings: number;
    fromCommitments: number;
    fromCashflows: number;
  };
  perFund: DiagnosticsFund[];
}

const RANGE_STORAGE_KEY = "reportmaker:last-range";
const CUSTOM_STORAGE_KEY = "reportmaker:last-custom";
const DEFAULT_BASE_CURRENCY = "USD";
const NET_VIEW_STORAGE_KEY = "reportmaker:net-view";

const buildDefaultRange = (): CustomRange => {
  const to = new Date();
  const from = new Date();
  from.setFullYear(to.getFullYear() - 5);
  return {
    from: from.toISOString().slice(0, 10),
    to: to.toISOString().slice(0, 10),
  };
};

const getStoredRange = (): TimeRangeOption => {
  if (typeof window === "undefined") {
    return quickRanges[1];
  }
  const stored = window.localStorage.getItem(RANGE_STORAGE_KEY);
  return quickRanges.find((option) => option.label === stored) ?? quickRanges[1];
};

const getStoredCustomRange = (): CustomRange => {
  if (typeof window === "undefined") {
    return buildDefaultRange();
  }
  try {
    const raw = window.localStorage.getItem(CUSTOM_STORAGE_KEY);
    if (!raw) {
      return buildDefaultRange();
    }
    const parsed = JSON.parse(raw) as CustomRange;
    if (parsed?.from && parsed?.to) {
      return parsed;
    }
    return buildDefaultRange();
  } catch {
    return buildDefaultRange();
  }
};

const emptyTotals = {
  contributions: 0,
  distributions: 0,
};

interface ToastState {
  message: string;
  requestId: string;
}

const App = () => {
  const [query, setQuery] = useState("");
  const [investors, setInvestors] = useState<Investor[]>([]);
  const [searchError, setSearchError] = useState<string | null>(null);
  const [selectedInvestor, setSelectedInvestor] = useState<Investor | null>(null);
  const [portfolio, setPortfolio] = useState<PortfolioSummary | null>(null);
  const [isSearching, setIsSearching] = useState(false);
  const [isLoadingPortfolio, setIsLoadingPortfolio] = useState(false);
  const [range, setRange] = useState<TimeRangeOption>(() => getStoredRange());
  const [customRangeDraft, setCustomRangeDraft] = useState<CustomRange>(() => getStoredCustomRange());
  const [customRangeApplied, setCustomRangeApplied] = useState<CustomRange>(() => getStoredCustomRange());
  const [toast, setToast] = useState<ToastState | null>(null);
  const [isExporting, setIsExporting] = useState(false);
  const [isPrinting, setIsPrinting] = useState(false);
  const [netView, setNetView] = useState<NetView>(() => {
    if (typeof window === "undefined") {
      return "invested";
    }
    const stored = window.localStorage.getItem(NET_VIEW_STORAGE_KEY);
    return stored === "toInvestor" ? "toInvestor" : "invested";
  });

  }, [query]);

  const resolveRange = useCallback((): CustomRange => {
    if (range.label === "Custom") {
      return customRangeApplied;
    }
    if (range.preset) {
      return resolvePresetRange(range.preset);
    }
    return customRangeApplied;
  }, [range, customRangeApplied]);

  const resolvedRange = resolveRange();
  const diagnosticsRangeKey = `${resolvedRange.from}|${resolvedRange.to}`;

  useEffect(() => {
    setDiagnostics(null);
    setDiagnosticsError(null);
    setDiagnosticsOpen(false);
    setIsDiagnosticsLoading(false);
  }, [selectedInvestor?.id, diagnosticsRangeKey]);

  const loadPortfolio = useCallback(async () => {
    if (!selectedInvestor) {
      return;
    }

    setToast(null);
    setIsLoadingPortfolio(true);
    try {
      const { from, to } = resolveRange();
      const summary = await fetchPortfolio(selectedInvestor.id, {
        from,
        to,
        baseCurrency: DEFAULT_BASE_CURRENCY,
      });
      setPortfolio(summary);
    } catch (err) {
      setPortfolio(null);
      const requestId = typeof crypto !== "undefined" && "randomUUID" in crypto ? crypto.randomUUID() : Date.now().toString();
      setToast({
        message: err instanceof Error ? err.message : "Failed to load portfolio.",
        requestId,
      });
    } finally {
      setIsLoadingPortfolio(false);
    }
  }, [selectedInvestor, resolveRange]);

  useEffect(() => {
    if (!selectedInvestor) {
      return;
    }
    void loadPortfolio();
  }, [selectedInvestor, loadPortfolio]);

  const handleSelectInvestor = useCallback((investor: Investor) => {
    setSelectedInvestor(investor);
    setInvestors([]);
    setQuery(investor.name);
    setPortfolio(null);
  }, []);

  const handleClearInvestor = useCallback(() => {
    setSelectedInvestor(null);
    setPortfolio(null);
    setQuery("");
    setInvestors([]);
    setSearchError(null);
  }, []);

  const handleApplyCustomRange = useCallback(() => {
    setCustomRangeApplied(customRangeDraft);
  }, [customRangeDraft]);

  const handleExportPdf = useCallback(async () => {
    if (!reportRef.current) {
      return;
    }
    setIsExporting(true);
    try {
      const canvas = await html2canvas(reportRef.current, { scale: 2 });
      const imgData = canvas.toDataURL("image/png");
      const pdf = new jsPDF("p", "mm", "a4");
      const pageWidth = pdf.internal.pageSize.getWidth();
      const pageHeight = (canvas.height * pageWidth) / canvas.width;
      pdf.addImage(imgData, "PNG", 0, 0, pageWidth, pageHeight);
      pdf.save(
        `investor-brief-${selectedInvestor?.name ?? "portfolio"}-${new Date().toISOString().slice(0, 10)}.pdf`,
      );
    } finally {
      setIsExporting(false);
    }
  }, [selectedInvestor]);

  const handlePrint = useCallback(() => {
    setIsPrinting(true);
    window.print();
    window.setTimeout(() => setIsPrinting(false), 600);
  }, []);

  const handleScrollToFunds = useCallback(() => {
    const target = document.getElementById("fund-metrics");
    if (target) {
      target.scrollIntoView({ behavior: "smooth" });
    }
  }, []);

  const summaryMetrics = useMemo(() => {
    if (!portfolio) {
      return [];
    }
    const { contributions, distributions } = portfolio.totals;
    const netCash = distributions - contributions;
    const netInvested = contributions - distributions;
    const netLabel = netView === "invested" ? "Net Invested" : "Net to investor";
    const netValue = netView === "invested" ? netInvested : netCash;
    const metrics = [
      {
        key: "contributions",
        label: "Total Contributions",
        value: formatCurrency(contributions, baseCurrency),
        tooltip: "Capital paid into funds during this range.",
      },
      {
        key: "distributions",
        label: "Total Distributions",
        value: formatCurrency(distributions, baseCurrency),
        tooltip: "Cash returned during this range.",
      },
      {
        key: "net",
        label: netLabel,
        value: formatCurrency(netValue, baseCurrency),
        delta: formatDelta(portfolio.deltas?.netCash ?? null),
        tooltip:
          netView === "invested"
            ? "Contributions minus distributions — capital still deployed."
            : "Distributions minus contributions — net cash back.",
      },
      {
        key: "investments",
        label: "# Holdings",
        value: formatNumber(portfolio.investmentsCount),
        delta: formatDelta(portfolio.deltas?.investments ?? null),
      },
    ];
    if (portfolio.insights?.cashflowIrr != null) {
      const irrValue = formatPercent(portfolio.insights.cashflowIrr * 100, 2);
      metrics.push({
        key: "irr",
        label: "Cash-flow IRR",
        value: portfolio.insights.irrExcludesUnrealized ? `${irrValue}*` : irrValue,
        tooltip: "Cash-flow IRR uses realized cashflows only; excludes unrealized NAV.",
      });
    }
    return metrics;
  }, [portfolio, baseCurrency, netView]);

  const recentActivity = portfolio?.insights.recentActivity;
  const recentRangeLabel =
    recentActivity && recentActivity.flows.length > 0
      ? `${formatIsoDate(recentActivity.flows[recentActivity.flows.length - 1]!.date)} — ${formatIsoDate(
          recentActivity.flows[0]!.date,
        )}`
      : "No cashflows";
  const activeHoldings = useMemo(() => {
    if (!portfolio) {
      return 0;
    }
    return portfolio.funds.filter(
      (fund) => Math.abs(fund.contributions ?? 0) > 0 || Math.abs(fund.distributions ?? 0) > 0,
    ).length;
  }, [portfolio]);
  const diagnosticsActiveCount = useMemo(() => {
    if (!diagnostics) {
      return 0;
    }
    return diagnostics.perFund.filter(
      (fund) => (fund.contributionsInRange ?? 0) !== 0 || (fund.distributionsInRange ?? 0) !== 0,
    ).length;
  }, [diagnostics]);
  const diagnosticsDormantFunds = useMemo(() => {
    if (!diagnostics) {
      return [];
    }
    return diagnostics.perFund
      .filter(
        (fund) => (fund.contributionsInRange ?? 0) === 0 && (fund.distributionsInRange ?? 0) === 0,
      )
      .slice(0, 10);
  }, [diagnostics]);

   const sectorRows = useMemo<BreakdownRow[]>(() => {
    if (!portfolio) {
      return [];
    }
    return Object.entries(portfolio.sectorBreakdown)
      .map(([name, values]) => ({
        name,
        value: values.totalValue,
        contribution: values.contribution,
        distribution: values.distribution,
        positions: values.positions,
      }))
      .sort((a, b) => b.value - a.value);
  }, [portfolio]);

   const countryRows = useMemo<BreakdownRow[]>(() => {
    if (!portfolio) {
      return [];
    }
    return Object.entries(portfolio.countryBreakdown)
      .map(([name, values]) => ({
        name,
        value: values.totalValue,
        contribution: values.contribution,
        distribution: values.distribution,
        positions: values.positions,
      }))
      .sort((a, b) => b.value - a.value);
  }, [portfolio]);

  const timelineData = useMemo(() => {
    if (!portfolio) {
      return [];
    }
    let rollingEquity = 0;
    return Object.entries(portfolio.annualBuckets)
      .sort(([a], [b]) => Number(a) - Number(b))
      .map(([year, values]) => {
        const net = values.netCash ?? values.distributions - values.contributions;
        rollingEquity += net;
        return {
          year,
          contributions: Math.abs(values.contributions),
          distributions: Math.abs(values.distributions),
          equity: rollingEquity,
        };
      });
  }, [portfolio]);

  const handleNetViewChange = useCallback((view: NetView) => {
    setNetView(view);
  }, []);

  const loadDiagnostics = useCallback(async () => {
    if (!selectedInvestor) {
      return;
    }
    setIsDiagnosticsLoading(true);
    setDiagnosticsError(null);
    try {
      const params = new URLSearchParams({
        contactId: String(selectedInvestor.id),
        from: resolvedRange.from,
        to: resolvedRange.to,
      });
      const response = await fetch(`/api/debug/investor?${params.toString()}`);
      if (!response.ok) {
        throw new Error(`Diagnostics request failed (${response.status})`);
      }
      const payload = (await response.json()) as InvestorDiagnostics;
      setDiagnostics(payload);
    } catch (error) {
      setDiagnosticsError(error instanceof Error ? error.message : "Failed to load diagnostics");
    } finally {
      setIsDiagnosticsLoading(false);
    }
  }, [selectedInvestor, resolvedRange.from, resolvedRange.to]);

  const handleDiagnosticsToggle = () => {
    const next = !isDiagnosticsOpen;
    setDiagnosticsOpen(next);
    if (next && !diagnostics && !isDiagnosticsLoading) {
      void loadDiagnostics();
    }
  };

  const summarizeFilters = (
    rangeValues: { from: string; to: string },
    base: string,
    lastSynced?: string,
  ) => {
    const parts = [
      `Range: ${formatIsoDate(rangeValues.from)} — ${formatIsoDate(rangeValues.to)}`,
      `Base: ${base}`,
      "Generated just now",
      `Source sync: ${formatIsoDate(lastSynced ?? "") || "—"}`,
    ];
    return parts.join(" • ");
  };

  const filterSummary = portfolio
    ? summarizeFilters(portfolio.timeRange, portfolio.timeRange.baseCurrency, portfolio.lastSynced ?? undefined)
    : summarizeFilters(resolvedRange, DEFAULT_BASE_CURRENCY);

  const actionsDisabled = !selectedInvestor || isLoadingPortfolio;
  const handleSliceClick = useCallback(() => undefined, []);

  return (
    <div className="app-shell">
      <Header
        investorName={selectedInvestor?.name}
        baseCurrency={baseCurrency}
        onExport={handleExportPdf}
        onPrint={handlePrint}
        disabled={actionsDisabled}
        isExporting={isExporting}
        isPrinting={isPrinting}
      />

      <div className="filters-grid">
        <InvestorPicker
          query={query}
          investors={investors}
          isSearching={isSearching}
          onQueryChange={setQuery}
          onSelect={handleSelectInvestor}
          selectedInvestor={selectedInvestor}
          onClear={handleClearInvestor}
          disabled={isLoadingPortfolio}
          error={searchError}
        />
        <TimeRangeTabs
          ranges={quickRanges}
          activeRange={range}
          onSelect={(option) => setRange(option)}
          customRange={customRangeDraft}
          onCustomChange={setCustomRangeDraft}
          onApplyCustom={handleApplyCustomRange}
          disabled={isLoadingPortfolio}
          isLoading={isLoadingPortfolio}
        />
      </div>

      <main className="report-body" ref={reportRef} id="report-root">
        <div className="sticky-summary">
          <div>
            <p className="label">Investor</p>
            <strong>{selectedInvestor?.name ?? "Awaiting selection"}</strong>
          </div>
          <div className="summary-right">
            <button
              type="button"
              className="holdings-chip"
              onClick={handleScrollToFunds}
              disabled={!portfolio}
            >
              {portfolio
                ? `${portfolio.investmentsCount} holdings • ${activeHoldings} active in range`
                : "Holdings pending"}
            </button>
            <p className="filters">{filterSummary}</p>
          </div>
        </div>

        {!selectedInvestor && (
          <div className="empty-state">
            <h2>Search for an investor to generate a brief</h2>
            <p>Use the search input above to find an investor, then pick a time range to load KPIs, charts, and tables.</p>
          </div>
        )}

        {selectedInvestor && (
          <>
            <SummaryCards metrics={summaryMetrics} isLoading={isLoadingPortfolio} />
            <div className="net-toggle">
              <span className="muted">View:</span>
              <div className="toggle-group" role="group" aria-label="Net view">
                <button
                  type="button"
                  className={`toggle-btn ${netView === "invested" ? "active" : ""}`}
                  onClick={() => handleNetViewChange("invested")}
                >
                  Net Invested
                </button>
                <button
                  type="button"
                  className={`toggle-btn ${netView === "toInvestor" ? "active" : ""}`}
                  onClick={() => handleNetViewChange("toInvestor")}
                >
                  Net to investor
                </button>
              </div>
            </div>
            {portfolio?.insights?.cashflowIrr != null && portfolio.insights.irrExcludesUnrealized && (
              <p className="helper-text irr-note">*Cash-flow IRR excludes unrealized NAV.</p>
            )}
            {recentActivity && (
              <section className="panel recent-activity">
                <div className="panel-header">
                  <h3>Recent activity (90d)</h3>
                  <span className="muted">{recentRangeLabel}</span>
                </div>
                <div className="recent-stats">
                  <div>
                    <p className="muted">Contributions</p>
                    <strong>{formatCurrency(-recentActivity.contributions90d, baseCurrency)}</strong>
                  </div>
                  <div>
                    <p className="muted">Distributions</p>
                    <strong>{formatCurrency(recentActivity.distributions90d, baseCurrency)}</strong>
                  </div>
                </div>
                <ul className="recent-flows">
                  {recentActivity.flows.length === 0 ? (
                    <li className="placeholder">No cashflows in the last 90 days.</li>
                  ) : (
                    recentActivity.flows.map((flow, index) => (
                      <li key={`${flow.fundId}-${flow.date}-${flow.type}-${index}`}>
                        <span className="flow-date">{formatIsoDate(flow.date)}</span>
                        <span className="flow-name">{flow.fundName ?? `Fund ${flow.fundId}`}</span>
                        <span className={`flow-amount ${flow.type}`}>
                          {formatCurrency(flow.amount, baseCurrency)}
                        </span>
                      </li>
                    ))
                  )}
                </ul>
              </section>
            )}
            {selectedInvestor && (
              <section className="panel diagnostics">
                <button
                  type="button"
                  className="diagnostics-toggle"
                  onClick={handleDiagnosticsToggle}
                  aria-expanded={isDiagnosticsOpen}
                >
                  Diagnostics
                  <span aria-hidden="true">{isDiagnosticsOpen ? "−" : "+"}</span>
                </button>
                {isDiagnosticsOpen && (
                  <div className="diagnostics-body">
                    {isDiagnosticsLoading && <p className="muted">Loading diagnostics…</p>}
                    {diagnosticsError && <p className="error-text">{diagnosticsError}</p>}
                    {diagnostics && !isDiagnosticsLoading && !diagnosticsError && (
                      <>
                        <p className="muted">
                          Sources — mappings: {diagnostics.sources.fromMappings}, commitments:{" "}
                          {diagnostics.sources.fromCommitments}, cashflows: {diagnostics.sources.fromCashflows}
                        </p>
                        <p className="muted">
                          Holdings: {diagnostics.unionFundCount} • Active in range: {diagnosticsActiveCount}
                        </p>
                        {diagnosticsDormantFunds.length > 0 ? (
                          <div>
                            <p className="muted">No in-range activity:</p>
                            <ul className="diagnostics-list">
                              {diagnosticsDormantFunds.map((fund) => (
                                <li key={fund.fundId}>
                                  <strong>{fund.fundName}</strong>{" "}
                                  <span>
                                    First flow: {fund.firstEverFlow ? formatIsoDate(fund.firstEverFlow) : "—"} • Last flow:{" "}
                                    {fund.lastEverFlow ? formatIsoDate(fund.lastEverFlow) : "—"}
                                  </span>
                                </li>
                              ))}
                            </ul>
                          </div>
                        ) : (
                          <p className="muted">All holdings have activity in this range.</p>
                        )}
                      </>
                    )}
                  </div>
                )}
              </section>
            )}
            <BreakdownCharts
              sectorRows={sectorRows}
              countryRows={countryRows}
              baseCurrency={baseCurrency}
              isLoading={isLoadingPortfolio}
              onSliceClick={handleSliceClick}
            />
            <AnnualTimeline data={timelineData} baseCurrency={baseCurrency} isLoading={isLoadingPortfolio} />
            <div id="fund-metrics">
              <FundTable
                funds={portfolio?.funds ?? []}
                baseCurrency={baseCurrency}
                totals={
                  portfolio
                    ? {
                        contributions: portfolio.totals.contributions,
                        distributions: portfolio.totals.distributions,
                      }
                    : emptyTotals
                }
                netView={netView}
                isLoading={isLoadingPortfolio}
              />
            </div>
            <footer className="footer-note">Internal use only. NAV values may be partial or preliminary.</footer>
          </>
        )}
      </main>

      {toast && (
        <div className="toast" role="alert">
          <div>
            <strong>Request failed</strong>
            <p>{toast.message}</p>
            <small>Request ID: {toast.requestId}</small>
          </div>
          <div className="toast-actions">
            <button
              type="button"
              className="btn secondary"
              onClick={() => {
                setToast(null);
                void loadPortfolio();
              }}
              disabled={isLoadingPortfolio || !selectedInvestor}
            >
              Retry
            </button>
            <button type="button" className="btn ghost" onClick={() => setToast(null)}>
              Dismiss
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default App;












