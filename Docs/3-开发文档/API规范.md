---
name: api-specification
scope: project
type: semantic
loaded: on-demand
description: API contract template for a project instance. Record protocols, models, authentication, and error boundaries separately.
---

# API Specification

> The template root does not prescribe an endpoint, provider, model, or business capability. After initialization, use code, configuration, interface contracts, and actual probes as the project instance's sources of truth. Leave unconfirmed items as `[fill in]`.

## Safety boundaries

- Never write real secrets, tokens, user data, or complete sensitive responses to tracked files.
- Store secrets only in the project's approved local secret store. Documentation records environment variable names or configuration entry points only.
- Handle partially sensitive settings such as base URLs and model names according to `操作系统/01_架构/三类行为铁律.md` and the project's ADRs.
- Redact logs and error examples. Document text must not contain reusable credentials.

## Project instance source of truth

| Priority | Evidence | Purpose |
|---|---|---|
| 1 | Interface implementation, client code, routes, and configuration schemas | Current behavior |
| 2 | Contract files such as OpenAPI, JSON Schema, or protobuf | Request and response structures |
| 3 | Actual probes, contract tests, and service logs | Availability and error behavior |
| 4 | This document | Summary and collaboration conventions |

## API inventory

| API / capability | Type | Caller | Service provider | Authoritative contract | Authentication | Status |
|---|---|---|---|---|---|---|
| [fill in] | External / internal / native | [fill in] | [fill in] | [fill in] | [fill in] | Pending verification |

## Protocol layer

The protocol layer describes how requests are transported and parsed; it is not tied to a particular provider or model. Complete at least these fields:

| Item | Current contract | Evidence |
|---|---|---|
| Protocol / version | [fill in] | [fill in] |
| Base URL configuration name | [fill in] | [fill in] |
| Path and method | [fill in] | [fill in] |
| Authentication header / signing method | [fill in] | [fill in] |
| Request Content-Type | [fill in] | [fill in] |
| Timeout | [fill in] | [fill in] |
| Retry conditions and limit | [fill in] | [fill in] |
| Streaming / nonstreaming | [fill in] | [fill in] |

This generic request illustrates structure only; it does not mean the project has adopted it:

```text
METHOD <BASE_URL>/<RESOURCE>
Headers:
  Authorization: <Defined by the project instance>
  Content-Type: <Fill in>
Body:
  <Complete according to the contract>
```

## Model layer

The model layer identifies the capability provider, model, or version. Keep it separate from the protocol layer. Compatibility with one protocol does not imply the same model, and changing a model must not silently change the request contract.

| Item | Current value | Authoritative configuration | Fallback strategy | Last verified |
|---|---|---|---|---|
| Provider | [fill in] | [fill in] | [fill in] | Pending verification |
| Model / version | [fill in] | [fill in] | [fill in] | Pending verification |
| Capability constraints | [fill in] | [fill in] | [fill in] | Pending verification |
| Data residency / compliance | [fill in] | [fill in] | [fill in] | Pending verification |

## Request and response contracts

Document each API separately. Do not combine several business capabilities into one ambiguous interface.

### [Fill in: API name]

- Purpose: [fill in]
- Call entry point: [fill in]
- Method and path: [fill in]
- Request schema: [fill in or link]
- Success response schema: [fill in or link]
- Error response schema: [fill in or link]
- Idempotency rules: [fill in]
- Permissions and privacy: [fill in]
- Contract tests: [fill in]

## Error handling

| Category | Retryable | Client behavior | Logging requirements |
|---|---|---|---|
| Missing configuration | No | Identify the missing setting; do not send a request | Do not log secret values |
| Authentication failure | No | Stop retrying and guide the user to update credentials | Record only the status code and redacted context |
| Rate limit | Yes | Follow the server's backoff instructions | Record attempt counts and wait times |
| Network / 5xx | Per contract | Bounded retries; never an infinite loop | Record the trace ID and a redacted summary |
| Contract parsing failure | No | Preserve the original error classification and degrade safely | Redact response content before retaining evidence |

## Changes and acceptance

- Update contract tests before implementation when protocols, authentication, fields, or error semantics change.
- Validate model changes separately for capability, cost, compliance, and fallback behavior; protocol compatibility is not a substitute.
- Retain real, redacted evidence of at least one success, one authentication failure, and one rate limit or service error.
- If documentation, code, and actual probes disagree, set the status to PENDING until the project instance's sources of truth are reconciled.

Historical references from the source project are not current template facts. Earlier endpoints, model names, and business functions remain traceable through Git history; do not keep embedding them in the current template.
