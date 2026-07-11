---
name: api-contract-validation
description: Repo-native API contract validation for request, response, error, auth, compatibility, client/server/docs/test alignment, without assuming OpenAPI, Zod, or Pact exists. Active v4.7.0 specialist skill with boundary-triggered command wiring.
---

# API Contract Validation

Prevent frontend/backend drift by verifying API contracts from the repo's actual implementation, tests, docs, and clients.

## Purpose

Help agents behave like senior backend/frontend engineers by protecting request, response, error, auth, and compatibility contracts using repo-native evidence.

## Read First

1. `<repo>/AGENTS.md`, `<repo>/NOW.md`, and active `<repo>/PLAN.md` if present
2. `.opencode/templates/PRD.md`, `.opencode/templates/QA_PLAN.md`, and `.opencode/templates/PROOF_OF_DONE.md`
3. API route handlers, validators, schemas, generated types, client fetchers/hooks, tests, and docs touched by the change
4. Existing API conventions for auth, errors, pagination, and versioning

## When to Use

- Touch list includes API route handlers, controllers, RPC handlers, server actions, validators, schemas, generated types, API clients/fetchers/hooks, API docs, or API tests that define or consume a boundary.
- A frontend client consumes a changed backend response.
- A request/response/error/auth shape changes.
- Auth/permission semantics, compatibility guarantees, or client/server boundary behavior changes.

## When Not to Use

- Pure UI work without API calls or contract changes.
- Pure backend internals that do not change public/internal API boundaries, client fetchers, generated types, API docs, or API tests.
- External API behavior that cannot be verified locally; document as `NOT_RUN` or external-contract risk.
- Use `N/A — <reason>; risk: <risk or none>` when no request, response, error, auth, client, server, docs, or test contract is affected.

## Repo-Native Contract Sources

Prefer sources already present in the repo:

- Route handlers/controllers/server actions
- TypeScript types/interfaces
- Runtime validators such as Zod/Yup/Valibot if present
- OpenAPI/GraphQL/Pact only if already present
- API client wrappers, fetch hooks, SDK adapters
- Tests and fixtures
- README/API docs

Do not assume OpenAPI, Zod, or Pact exists.

## Procedure

1. List changed endpoints/actions and their owning files.
2. Extract request shape: method/action, path, params, query, body, headers, auth requirements.
3. Extract response shape: success status, body fields, nullability, pagination, side effects.
4. Extract error shape: status codes, error envelope, validation errors, conflict/permission semantics.
5. Compare server implementation against client usage, docs, tests, fixtures, and generated types.
6. Check auth/permission semantics: unauthenticated, unauthorized, ownership, role, tenant/company boundaries.
7. Check backward compatibility: removed fields, renamed fields, changed defaults, changed status codes, stricter validation.
8. Add or identify schema examples for at least one success and one error path when practical.
9. Classify non-pass outcomes using v4.6.1 labels: `TARGETED_FAILURE`, `BROAD_BASELINE_FAILURE`, `FLAKY_OR_INFRA_FAILURE`, `NOT_RUN`, `ACCEPTED_NON_BLOCKING`, or `BLOCKING_UNKNOWN`.

## Evidence Requirements

- Endpoint/action list with file paths
- Request/response/error shape summary
- Client/server/docs/test alignment notes
- Auth/permission semantics evidence
- Compatibility verdict and owner-approved breaking changes, if any

## Output Format

```markdown
## API Contract Validation Report

Contract source: <repo-native source paths>
Endpoints/actions: <list>

| Endpoint/action | Request | Response | Errors | Auth/permission | Compatibility | Verdict |
|---|---|---|---|---|---|---|
| <name> | <shape> | <shape> | <shape> | <semantics> | <compatible/breaking/unknown> | <PASS/FAIL> |

Client/server/docs/tests alignment: <PASS/FAIL/N/A>
Schema examples: <paths or inline summary>
Gate classification if non-pass: <v4.6.1 label>
Required follow-up: <none or actions>
```

## Failure Conditions

- Client expects fields/status/errors that server no longer returns.
- Server accepts or requires fields not documented or tested when contract is public to the app.
- Auth/permission semantics are unclear for changed endpoints.
- Breaking change lacks migration, compatibility plan, or owner approval.
- Contract cannot be determined; classify as `BLOCKING_UNKNOWN`.

## Related Templates

- Product behavior belongs in `.opencode/templates/PRD.md`.
- Verification cases belong in `.opencode/templates/QA_PLAN.md`.
- Final contract evidence belongs in `.opencode/templates/PROOF_OF_DONE.md`.
