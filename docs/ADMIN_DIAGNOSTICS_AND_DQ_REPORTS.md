# Admin Diagnostics & Data-Quality (DQ) Reports

This document describes the **admin-only diagnostics surface** and the **Data-Quality Reconciliation API** that compares raw cashflows against the annual timeline aggregates used in the investor brief/PDF.

> **Audience:** Engineers, QA, and internal support.  
> **Scope:** `GET /admin/dq/reports` (implemented), supporting utilities, auth/audit expectations, pagination, and CSV export guidance.

---

## 1) Overview

The diagnostics layer helps verify that reporting aggregates match the underlying transactions. It answers:

* *Do the yearly (or quarterly/monthly) **In/Out** totals in the brief/PDF reconcile with raw cashflows?*
* *Where are discrepancies and what transactions likely caused them?*

Key properties:

* **Admin-only** route, protected by token middleware and audited.
* **Configurable tolerance** in basis points (bps) per leg (In/Out).
* **Explainability** via top contributors (investmentId, txType, amount).
* **Machine-readable JSON** and CSV-friendly structure.

---

## 2) Authentication, Authorization & Audit

### Authentication

Use `Authorization: Bearer <token>` for all admin endpoints. For legacy compatibility only, `x-admin-token: <token>` is also accepted but may be removed later.

* **Authorization:** enforced by `requireAdmin` middleware.
* **Audit:** `auditAdmin` logs *actor*, *route*, *query params* (`investorId`, `from`, `to`, `groupBy`, `toleranceBps`, pagination), *resultCount*, and *requestId*.
* **Headers:**
  * Accepts optional `X-Request-Id` (generated if absent).
  * Returns `X-Request-Id` echo for log correlation.

> **Security note:** Route is for **internal use only**. Do not expose via public ingress.

---

## 3) API - Data-Quality Reconciliation

**Route:** `GET /admin/dq/reports`

### 3.1 Query Parameters

| Name           | Type                               |     Default | Description |
| -------------- | ---------------------------------- | ----------: | ----------- |
| `investorId`   | `string`                           |           - | Optional: when omitted, the service runs a paginated reconciliation across all investors (`limit`, `cursor` apply). Provide `investorId` to scope the report to a single investor. |
| `from`         | `ISO date`                         | dataset min | Inclusive lower bound of the cashflow/timeline window. |
| `to`           | `ISO date`                         | dataset max | Inclusive upper bound of the window. |
| `groupBy`      | `"year" \| "quarter" \| "month"` |    `"year"` | Period granularity. |
| `toleranceBps` | `number`                           |        `50` | Max allowed absolute delta in bps vs **expected** per leg (In/Out). |
| `limit`        | `number`                           |       `100` | Page size when `investorId` is omitted. |
| `cursor`       | `string`                           |           - | Opaque pagination token from prior response. |

### 3.2 Semantics

* **Expected series** = output of the **timeline builder** used by the UI/PDF for the same period and grouping.
* **Actual series** = raw cashflows (Vantage) re-aggregated by the same rules:
  * `contribution` -> **In**
  * `distribution` -> **Out** (absolute value)
* **Delta** = `actual - expected` per leg.
* **Delta bps** = `abs(delta) / max(1, abs(expected)) * 10000`
  * If `expected == 0 && actual != 0` -> `Infinity` bps.
* **Status** per period = `ok` iff both legs are within tolerance; else `out_of_tolerance`.
* All amounts are returned as positive magnitudes in base currency. `Out` values are positive; clients should not expect negative numbers for distributions.
* For formulas (delta, deltaBps) and the `expected=0 -> Infinity` rule, see `docs/calculation-rules.md`.

### 3.3 Response (200)

```json
{
  "scope": {
    "investorId": "abc123",
    "from": "2018-01-01",
    "to": "2025-12-31",
    "groupBy": "year",
    "toleranceBps": 50
  },
  "items": [
    {
      "period": "2021",
      "expected": { "in": 2500000, "out": 800000 },
      "actual":   { "in": 2500000, "out": 820000 },
      "delta":    { "in": 0,        "out": 20000  },
      "deltaBps": { "in": 0,        "out": 250    },
      "contributors": [
        { "investmentId": "hold-45", "txType": "distribution", "amount": 20000 }
      ],
      "status": "out_of_tolerance"
    }
  ],
  "nextCursor": null,
  "generatedAt": "2025-11-06T09:00:00Z"
}
```

### 3.4 Error Codes

| HTTP | Meaning           | Notes |
| ---: | ----------------- | ----- |
|  400 | Bad request       | Invalid dates, params, or groupBy value. |
|  401 | Unauthorized      | Missing/invalid token. |
|  403 | Forbidden         | Token not admin-scoped. |
|  429 | Too Many Requests | Rate limit exceeded (admin endpoints). |
|  500 | Internal error    | Includes `X-Request-Id` for log lookup. |

---

## 4) Examples

### 4.1 Reconcile one investor (yearly)

```bash
curl -s \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "X-Request-Id: dq-demo-1" \
  "https://<host>/admin/dq/reports?investorId=INV-123&from=2018-01-01&to=2025-12-31&groupBy=year&toleranceBps=50"
```

### 4.2 All investors, quarterly, paginated

```bash
curl -s \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  "https://<host>/admin/dq/reports?groupBy=quarter&limit=100"
# follow-up page
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" "https://<host>/admin/dq/reports?cursor=<nextCursor>"
```

### 4.3 CSV export (jq)

```bash
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "https://<host>/admin/dq/reports?investorId=INV-123" \
| jq -r '
  [.items[]]
  | ("period,expected_in,expected_out,actual_in,actual_out,delta_in,delta_out,delta_in_bps,delta_out_bps,status"),
    (.[] | [
      .period,
      .expected.in, .expected.out,
      .actual.in, .actual.out,
      .delta.in, .delta.out,
      .deltaBps.in, .deltaBps.out,
      .status
    ] | @csv)
'
```

---

## 5) Frontend Diagnostics (guidance)

* Create admin-gated route **`/admin/diagnostics`** featuring:
  * Filter bar: `investorId`, `from`, `to`, `groupBy`, `toleranceBps`.
  * Summary tiles: total periods checked, out-of-tolerance count, max delta bps.
  * Table: one row per period with badges and a **"View contributors"** drill-down.
  * Actions: **Export CSV**, **Copy cURL**, **Refresh**.
* Error handling: show toast with HTTP code + request-id; allow retry.
* Accessibility: keyboard navigation for table and modal.

---

## 6) Configuration

* `dq.toleranceBpsDefault` - default 50 bps.
* `dq.allowedGroupings` - `['year','quarter','month']`.
* `dq.maxPageSize` - default 100.
* **Stale NAV settings** documented separately (see `docs/calculation-rules.md`); may be surfaced on the same diagnostics page.

---

## 7) Observability & Rate Limiting

* **Logs**: structured logs include `requestId`, actor, route, params, resultCount, duration.
* **Metrics**: count of reports generated, out-of-tolerance periods, cache hit ratio if applicable.
* **Rate limits** (recommended): e.g., 60 req/min per admin token; 10 req/min for all-investors scans.

---

## 8) Troubleshooting

* **Empty `items`**: either perfect reconciliation or incorrect filter window.
* **Many `Infinity` bps entries**: expected side is zero, so the timeline builder may be skipping transactions in that period; verify the classification map.
* **401/403**: validate token and admin scope.
* **CSV shows negative Out**: ensure consumers treat Out as absolute; the API returns Out as positive magnitudes.

---

## 9) Change Log

* **V1-DQ-01**: Initial reconciliation endpoint, admin auth/audit, docs and examples.

---

## 10) Appendix - TypeScript Shapes (for reference)

```ts
export type DQItem = {
  period: string;
  expected: { in: number; out: number };
  actual: { in: number; out: number };
  delta: { in: number; out: number };
  deltaBps: { in: number; out: number };
  contributors?: Array<{ investmentId: string; txType: "contribution"|"distribution"; amount: number }>;
  status: "ok" | "out_of_tolerance";
};

export type DQReport = {
  scope: { investorId?: string; from?: string; to?: string; groupBy: "year"|"quarter"|"month"; toleranceBps: number };
  items: DQItem[];
  nextCursor?: string | null;
  generatedAt: string;
};
```

---

## Related docs

- Calculation rules & reconciliation semantics -> `docs/calculation-rules.md`
- Endpoint details & admin headers -> `docs/diagnostics.md`