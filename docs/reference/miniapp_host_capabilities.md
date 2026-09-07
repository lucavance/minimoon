# MiniApp host capabilities

Application code requests host work through typed root functions. It never
constructs an internal command object or calls raw `wx.*` APIs.

## Flow

```text
update returns with_cmd(model, command)
  -> root command function binds an Emit[Result]
  -> runtime allocates request ID and continuation
  -> InvokeCapability command
  -> host verifies the page declaration
  -> wx.* success/fail callback
  -> ordered resolve-effect scheduler entry
  -> MoonBit decoder produces a typed Result
  -> emitter routes the owning state message
```

MoonBit-owned `effect`, `perform`, and `attempt` do not invoke `wx.*` or pass
through a host-result decoder. Their suspended completion emits an owned local
message, requests a sequence-watermarked drain, and re-enters the same page
scheduler without crossing an intervening scheduler entry.

The first terminal result wins. Unknown, duplicate, late, canceled, or post-
dispose results cannot dispatch another message.

## Public command surface

| Public command | Boundary | Page declaration |
|---|---|---|
| `delay` | page-owned `minimoon.timeout` host timer | none |
| `login` | `wx.login` | `Login` |
| `get_storage` | `wx.getStorage` | `GetStorage` |
| `set_storage` | `wx.setStorage` | `SetStorage` |
| `request` | `wx.request` | `Request` |
| `show_toast` | `wx.showToast` | `ShowToast` |
| `get_location` | `wx.getLocation` | `GetLocation` |
| `choose_media` | `wx.chooseMedia` | `ChooseMedia` |
| `request_payment` | `wx.requestPayment` | `RequestPayment` |
| `navigate_to` | `wx.navigateTo` | `NavigateTo` |
| `redirect_to` | `wx.redirectTo` | `RedirectTo` |
| `navigate_back` | `wx.navigateBack` | `NavigateBack` |
| `navigate_back_or` | back or redirect fallback | `NavigateBack`, `RedirectTo` |

Example:

```moonbit
LoginRequested => @minimoon.with_cmd(
  current,
  @minimoon.login(emit.map(result => LoginFinished(result))),
)
```

Capabilities use root `Capability`; routes use `Route`; payment input uses
`PaymentParams`; failures use `HostError` and `HostErrorKind`. Every `wx.*`
operation must appear in the page declaration. Undeclared or unavailable
methods are rejected by the host.

## HTTP requests

`request(url, resolve, http_method?, query?, headers?, body?, timeout_ms?)`
uses `HttpMethod::{Get, Post, Put, Delete, Head, Options}` (default `Get`).
The label is `http_method` because MoonBit reserves `method`.
Declare `Request` in the page's capabilities. For example:

```moonbit
@minimoon.request(
  "https://httpbingo.org/post",
  emit.map(result => RequestFinished(result)),
  http_method=Post,
  query=[@minimoon.query("tag", "one"), @minimoon.query("tag", "two")],
  headers={ "X-Minimoon-Test": "public-smoke" },
  body=JsonBody(Json::object({ "message": Json::string("测试") })),
  timeout_ms=15000,
)
```

`JsonBody(Json)` serializes exactly once. `FormBody(Array[(String, String)])`
uses UTF-8 percent encoding, including `%20` for spaces, and preserves repeated
fields. `TextBody(String)` is sent unchanged. Queries use the same encoding,
preserve order/duplicates and append to an existing URL query. Supply raw values,
not pre-escaped values. No body, JSON `null`, and empty text remain distinct.

Default body content types are `application/json`,
`application/x-www-form-urlencoded`, and `text/plain; charset=utf-8`.
Explicit JSON content types may also be `application/*+json`; form types must
match form encoding. Matching ignores case and parameters. Text permits a
caller-selected content type. Conflicts produce an error, not an override.
Request header names are normalized to lowercase; duplicate case variants,
invalid names/values and `Referer` are rejected. Response header names retain
host casing; cookies retain the existing result representation.

URLs must be absolute HTTPS without credentials, whitespace or fragments.
GET/HEAD bodies and non-positive timeouts are rejected. Omitted timeouts use
the host default. Arguments are snapshotted at command construction; validation
errors are delivered only when the command runs, without network access and
without echoing URL credentials, request bodies or headers into error metadata.
There are no implicit retries, binary bodies, response-format options or PATCH
support. HTTP 400/401/500 still return `Ok(RequestResult)`; inspect
`status_code` for application policy. Transport failures return `Err(HostError)`.
Outstanding request tasks are aborted on page disposal and late results ignored.

## Result normalization

- login: `Result[LoginResult, HostError]`
- storage: `Result[StorageResult, HostError]`
- request: `Result[RequestResult, HostError]`
- location/media: typed `LocationResult` and `ChooseMediaResult`
- set-storage, toast, payment success: `Unit`
- malformed success payload: `InvalidPayload`

Request status and optional media size/width/height values must be exact
integers in `0..2147483647`; fractional, negative, overflowing, or wrongly
typed fields produce `InvalidPayload`. Numeric values are never truncated or
coerced to strings.

Runtime ABI v10 carries callback JSON into root-owned MoonBit decoders before
application state receives a result and gives suspended local effects a
generation-bound, sequence-watermarked host wake path. Only same-turn or
adjacent drain watermarks coalesce; intervening scheduler entries remain
ordering barriers. Page disposal suppresses arbitrary local async delivery; it
does not promise physical cancellation of an application-supplied async
function. Framework `delay` is physically canceled with `clearTimeout`.

## Generated-host coverage

The navigation/host smoke mounts the real generated Home page against a mock
`wx` boundary. It asserts exact outbound payloads and successful state delivery
for login, storage get/set, request, toast, location, and media, in that order.
It separately covers failed login, unavailable location, and an outstanding
request that unload aborts exactly once; invoking that request's saved success
callback afterward must not change page data or recreate a pending effect.

This is deterministic automated coverage of generated JavaScript, not a claim
that the current fingerprint passed WeChat Developer Tools. The real-host
checklist remains required, and payment remains backend/account-owned rather
than part of this mock success workflow.

The host suite also runs the generated Home HTTP scenarios offline, including
timeout, synchronous failure, unavailable API, malformed response, concurrent
out-of-order completion, duplicate callbacks and unload cancellation.
`bun run check:http-live` loads the same generated page and uses a Bun-fetch
`wx.request` transport shim against [httpbingo](https://httpbingo.org/).
It sends fixed synthetic data, serially, without retries; report output is
`_build/http-live/report.json`. `MINIMOON_HTTP_BASE_URL` can point to an HTTPS
service implementing the same httpbingo echo protocol. This opt-in network
check is excluded from CI/candidate/release gates. It neither uses credentials
nor creates real-host evidence, and does not replace the
[WeChat checklist](../operations/miniapp_devtools_validation.md).

## Backend and privacy boundaries

`wx.login` returns only a front-end code. Session exchange, tokens, and account
policy belong to an app backend. `wx.requestPayment` requires backend-signed
parameters; Minimoon does not create orders, hold merchant secrets, verify
callbacks, or process refunds. Privacy-sensitive capabilities still require
application declarations, permission UX, and platform review.

## Accepting a new capability

A new capability needs root-owned types, declared-capability validation,
success/failure/unavailable and late-result tests, generated-host simulation,
documented backend/privacy ownership, artifact-size review, and a real-host
checklist before it is supported.
