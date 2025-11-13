# Calculation Rules & Reconciliation Semantics

This note captures the math used by the investor brief timeline, the admin Data-Quality reports, and any downstream CSV exports.

## Base Concepts

- All cashflow amounts are expressed as **positive magnitudes** in the base currency.
  - Contributions (capital in) are treated as `in`.
  - Distributions (capital out) are treated as `out` and remain positive.
- Periods can be aggregated by year, quarter, or month using the same bucketing rules across UI, PDF, and diagnostics.

## Delta Formulas

Given an expected timeline value (derived from the production timeline builder) and an actual value (recomputed from raw cashflows):

- `delta = actual - expected`
- `delta_in_bps = abs(delta_in) / max(1, abs(expected_in)) * 10000`
- `delta_out_bps = abs(delta_out) / max(1, abs(expected_out)) * 10000`

Use integer math where possible, but preserve decimals in reporting/output so QA can see the precise variance.

### Expected Zero Handling

If the expected value for a leg is zero but the actual value is non-zero, treat the basis-point delta as **Infinity**. This flags that the underlying classification logic missed a transaction entirely.

## Examples

```text
delta_out_bps example
----------------------
expected.in  = 2_500_000
actual.in    = 2_500_000
expected.out =   800_000
actual.out   =   820_000

delta.in  = 0
delta.out = 20_000

delta_out_bps = abs(20_000) / max(1, 800_000) * 10_000 = 250
```

## Related docs

- Admin diagnostics & DQ walkthrough -> `docs/ADMIN_DIAGNOSTICS_AND_DQ_REPORTS.md`
- Endpoint contract and headers -> `docs/diagnostics.md`