# IR Prep — Work Plan (No Dates)

## Executive Summary
Phased roadmap to complete the Investor Relations meeting-prep dashboard and exports. Focus is on scope, acceptance criteria, and ticketable deliverables—no calendars, just sequence.

## 1. Scope Recap
- **Data & calculations**: Auto-classify cashflows, aggregate NAV (with Missing/Stale flags), enrich with sector/country metadata, build annual cash-flow buckets.
- **Time ranges**: Presets for last 3/5/10/12 years, “All”, and Custom window.
- **Breakdowns & visuals**: Sector and Country pies plus tables; annual In vs Out timeline; equity curve and quarterly bars.
- **UX & exports**: Investor search, KPI overview (Equity, Net Cash, NAV status, investment count), PDF/CSV exports with investor info, disclaimer, and timestamp.
- **DQ & integration**: Pull holdings/cashflows/financials from Vantage, normalize dates, surface missing NAV and unmapped transaction warnings.

## 2. Phased Delivery (sequence only)
### Phase MVP — Internal view + PDF export *(in place)*
- Investor picker loads Vantage data (investments, cashflows, valuations when present).
- KPIs for Equity, Net Cash, NAV status (Missing/Stale tags).
- Static Sector/Country pies with detail tables.
- Annual contributions vs distributions timeline.
- Date filters: 3/5/10/12/All/Custom.
- PDF/CSV exports with investor info, timestamp, disclaimer.

### Phase V1 — Data-quality & observability hardening
1. **DQ reconciliation**
   - Recompute S cashflows per period and compare with timeline aggregates; emit discrepancies (investor/year/instrument).
   - `/admin/dq/reports` endpoint returning machine-readable payload; nightly job stores results.
   - UI diagnostics page exposing last run, counts, CSV download.

2. **Stale NAV warnings**
   - Configurable `staleNavThresholdDays`.
   - API marks positions beyond threshold; UI badges on KPI card & fund rows; PDF disclaimer auto-references stale valuations.

3. **ERP client caching**
   - TTLs: Contacts/Maps ˜15m, Financials ˜5m, Cashflows ˜1m (all configurable).
   - Namespaced cache keys, request-id propagation, cache metrics.
   - `?nocache=1` query override for support.

4. **Diagnostics & logging**
   - `/admin/diagnostics` (feature-flagged) reporting build hash, cache stats, DQ summary, latest export events.

5. **Investment rating surfacing**
   - If Vantage supplies rating, display; otherwise show “Not available” with tooltip to documentation.

### Phase V1.5 — Interactivity & security readiness
1. **Interactive pies**
   - `onSliceClick` opens modal/panel with sub-sectors/funds/positions, filters, export.

2. **Timeline drill-down**
   - Year block toggles quarterly/monthly view when data density allows; aggregates reconcile.

3. **Security groundwork**
   - Define auth model (SSO or token links), add rate limiting on exports/API, persist audit events (export/login/data fetch).

4. **Security messaging**
   - Persistent “Internal use only” banner in UI and PDF footer.

## 3. Acceptance Criteria
- **Investor selection**: Search returns results quickly; selection displays name/ID/#investments.
- **Sector/Country pies**: Totals reconcile (100%); tables match chart slices; drill-down behaves as specified (post V1.5).
- **Annual timeline**: Each year shows In/Out; sums match cash-flow aggregates; tooltips show values/counts.
- **KPIs**: Equity/Net Cash respect selected range; NAV status reflects Missing/Stale conditions.
- **PDF/CSV exports**: Contain KPIs, breakdowns, timestamp, disclaimer; printable layout; export actions auditable.
- **Security/Observability**: Internal-only access; audit events capture actor/action/target/time; rate limits return 429 on burst; diagnostics gated by role/flag.

## 4. Test Plan
### Backend
- Unit: cashflow classifier, annual bucket builder, stale NAV detector, cache TTL behavior.
- Integration: Vantage client, reconciliation job, admin endpoints.
- Contract: `/portfolio`, `/admin/dq/reports`, `/admin/diagnostics` response schemas.

### Frontend
- Component: KPI cards, pies, timeline, security banner.
- Interaction: Pie slice click ? modal; timeline year click ? quarter/month toggle.
- Snapshot: PDF content (key text & disclaimer present), export flows.

### E2E
- Investor happy path through export PDF/CSV.
- Diagnostics visibility and `?nocache=1` override tested.

## 5. Observability & Ops
- Structured logs include `request-id` and user context.
- Metrics: cache hit ratio, export counts, DQ error rates, stale NAV counts.
- Alerts: thresholds for DQ error rate, export failure rate, cache misses/latency; dashboards for API latency and cache performance.

## 6. Risks & Mitigations
- **NAV availability**: Keep Missing/Stale signals; avoid performance claims without valuations.
- **Cache inconsistencies**: Short TTLs + `nocache` override; display data timestamps.
- **Chart performance**: Virtualize large tables, debounce user interactions, lazy-load drill-down data.

## 7. Jira-Ready Ticket Examples
- `V1-DQ-01`: Reconciliation job & `/admin/dq/reports` endpoint — BE.
- `V1-NAV-02`: Stale NAV configuration + UI indicators — BE/FE.
- `V1-CACHE-03`: Cache TTLs, metrics, `nocache` param — BE.
- `V1-DIAG-04`: Diagnostics page (feature-flagged) — FE.
- `V1-RATE-05`: Rate limiting exports & portfolio API — BE.
- `V1-RATING-06`: Investment rating display/placeholder — FE.
- `V1.5-PIE-07`: Pie slice drill-down modal + export — FE.
- `V1.5-TIME-08`: Timeline quarter/month drill-down — FE.
- `V1.5-AUDIT-09`: Audit event store & viewer — BE/FE.
- `V1.5-MSG-10`: Security banner + PDF footer note — FE.

**Definition of Done** (per ticket): tests pass, documentation updated, logs/metrics observable, acceptance criteria met, change reviewed and merged.

## 8. Documentation To Add
- `/docs/calculation-rules.md` — definitions & examples for Net Cash, Equity, NAV.
- `/docs/security-sharing.md` — internal-only policy, security messaging, future sharing model.
- `/docs/diagnostics.md` — admin endpoints, redaction guidelines, access control.
