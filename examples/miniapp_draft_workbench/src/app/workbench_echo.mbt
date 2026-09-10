///|
pub fn echo_base_url() -> String {
  "https://echo.apifox.com"
}

///|
pub fn initial_echo() -> EchoModel {
  { token: 0, revision: -1, submitted: empty_draft(), status: EchoIdle, }
}

///|
pub fn echo_label(echo : EchoModel, revision : Int) -> String {
  if echo.status != EchoIdle && echo.revision != revision {
    return if echo.status == EchoLoading {
      "发送中；内容已修改，旧响应不会用于当前草稿。"
    } else {
      "内容已修改，请发送当前内容。"
    }
  }
  match echo.status {
    EchoIdle => "尚未发送。"
    EchoLoading => "正在发送…"
    EchoOk(_) => "回显成功（不等于云端保存）。"
    EchoFailed(message) => message
    EchoOutdated => "旧响应已忽略，请发送当前内容。"
  }
}

///|
pub fn finish_echo(
  current : EchoModel,
  token : Int,
  revision : Int,
  result : Result[DraftEcho, Error],
) -> EchoModel {
  if current.token != token || current.status != EchoLoading {
    return current
  }
  let status = if current.revision != revision {
    EchoOutdated
  } else {
    match result {
      Ok(echo) if echo.json == current.submitted => EchoOk(echo.json)
      Ok(_) => EchoFailed("回显内容不匹配，请重试。")
      Err(@http.BadStatus(response)) =>
        EchoFailed(
          "HTTP " + response.status_code.to_string() + "，请重试。",
        )
      Err(@http.RequestError(_)) =>
        EchoFailed("网络请求失败或超时，请检查网络后重试。")
      Err(_) => EchoFailed("响应格式错误，请重试。")
    }
  }
  { ..current, status, }
}

///|
pub fn echo_request(
  draft : Draft,
  resolve : @minimoon.Emit[Result[DraftEcho, Error]],
) -> @minimoon.Cmd {
  @http.post(echo_base_url() + "/post", timeout_ms=10000)
  .with_json(draft)
  .expect_json(resolve)
}
