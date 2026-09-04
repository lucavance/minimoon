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
