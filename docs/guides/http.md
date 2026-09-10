# Typed HTTP requests

Import the optional `lampclaw/minimoon/http` package as `@http`, alongside the
root `lampclaw/minimoon` package. It is part of core 0.2.0, not a separate
module or a dependency on Rabbita's browser runtime. Pages or applications
executing requests must declare the root `Request` capability.

```moonbit
struct Profile {
  name : String
} derive(ToJson, @json.FromJson)

fn save(profile : Profile, receive : @minimoon.Emit[Result[Profile, Error]]) -> @minimoon.Cmd {
  @http.post("https://example.com/profile")
    .with_json(profile)
    .expect_json(receive)
}
```

The URL above is illustrative. Both maintained public-API fixtures use
[Apifox Echo](https://echo.apifox.com/); a successful echo proves request transport and decoding,
not server-side persistence. Real business applications must use their own
authenticated service and configure its domain in WeChat.

`get` and `delete` return `Request`; `post` and `put` return `RequestWithBody`.
Every constructor accepts ordered `query`, `headers` and `timeout_ms` options.
Use `with_json` for `ToJson` values or `with_text` for text; omitting the body is
also allowed. `expect_json` infers the decoded type from
`Emit[Result[T, Error]]`, so `emit.map(result => Saved(result))` and `create_resource` compose
without a second effect system.

Only 2xx responses are decoded as success. Errors remain matchable:

- `@http.HttpError::RequestError(error)` retains the original `HostError`.
- `@http.HttpError::BadStatus(response)` retains status, headers and response data.
- JSON decoding failures retain the original `@json.JsonDecodeError`, including
  its path and expected type; they are not flattened into strings.

The root `@minimoon.request` remains available for raw status handling and the
full method/body surface, including form encoding, HEAD and OPTIONS. Raw
requests still deliver non-2xx HTTP responses as successful transport results.

Builders snapshot request arguments. Execution, capabilities, cancellation and
late-result rejection use the existing root runtime: a page command belongs to
that page; an application command belongs to the application even if a page
first emitted its message. Disposing the owner cancels pending host work;
hidden pages do not implicitly abort application requests. There are no hidden
retries, timers, caches or process-global clients.

For HTTP command tests, inject host replies with the owning low-level public
`PageRuntime.resolve_effect` or `AppRuntime.resolve_effect`, then drain ready
work with `has_ready_work` and `flush`, using a bounded loop. The higher-level
`TestRuntime` and `TestApp`
harnesses instead provide `quiesce()` for ready local/shared work; they do not
inject HTTP replies or wait for a network request. `bun run check:http-live`
remains an explicit public-API smoke, not WeChat Developer Tools evidence.
It checks ten Platform cases, the App-owned draft echo and the UI Form echo.
The probe accepts scalar/array-valued query, form and header echoes without losing
repeated values. It always checks the outbound method, and checks the echoed
method as well when supplied; Apifox does not include that field on `/post`.

The builder API follows Rabbita source at
[`eccae750`](https://github.com/moonbit-community/rabbita/tree/eccae7507360aec8465469bafb7fb4da5b260a2a/rabbita/http),
reviewed 2026-09-08. Source APIs take precedence over older upstream tutorial
snippets. See [third-party notices](../../THIRD_PARTY_NOTICES.md).
