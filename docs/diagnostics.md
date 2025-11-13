# Admin Diagnostics Endpoint Reference

This document outlines the `/admin/dq/reports` contract, headers, and operational notes for internal users.

## Authentication

Use `Authorization: Bearer <token>` for all admin endpoints. For legacy compatibility only, `x-admin-token: <token>` is also accepted but may be removed later. Ensure tokens are scoped for admin access.

## Required Headers

- `Authorization: Bearer <token>`
- `X-Request-Id` (optional): include to make log correlation easier; the service echoes the value in the response. A value is generated when the header is omitted.
- `Content-Type: application/json` is implied for responses.

## Endpoint

### GET /admin/dq/reports

Query parameters:

| Name           | Type                               | Default | Notes |
| -------------- | ---------------------------------- | ------: | ----- |
| `investorId`   | `string`                           |   —     | Optional: when omitted the service runs a paginated reconciliation across all investors (`limit`, `cursor` apply). Provide an ID to scope the report to a single investor. |
| `from`         | `ISO date`                         | dataset min | Inclusive lower bound for the cashflow/timeline window. |
| `to`           | `ISO date`                         | dataset max | Inclusive upper bound for the window. |
| `groupBy`      | `"year" \| "quarter" \| "month"` | `"year"` | Period granularity. |
| `toleranceBps` | `number`                           | `50` | Maximum tolerated absolute delta (in basis points) per leg. |
| `limit`        | `number`                           | `100` | Page size when scanning across investors. |
| `cursor`       | `string`                           | — | Opaque pagination token from the previous response. |

Responses follow the structure described in `docs/ADMIN_DIAGNOSTICS_AND_DQ_REPORTS.md`. All amounts are returned as positive magnitudes; `out` values remain positive to represent distributions.

## CSV Export Guidance

The API returns machine-readable JSON. For CSV output, reuse the jq snippet in `docs/ADMIN_DIAGNOSTICS_AND_DQ_REPORTS.md` (period, expected/actual in/out, deltas, delta bps, status). If a UI or script emits CSV directly, match those columns so QA can diff outputs consistently.

## Observability

- Ensure every request carries or receives an `X-Request-Id`.
- Structured logs capture actor, route, query parameters, result counts, and duration.
- Monitor rate limits (recommended 60 req/min per admin token; 10 req/min for full scans) and alert on spikes.

## Related docs

- Aggregation math and sign conventions -> `docs/calculation-rules.md`
- Full diagnostics workflow -> `docs/ADMIN_DIAGNOSTICS_AND_DQ_REPORTS.md`