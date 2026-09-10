///|
pub struct Model {
  storage_input : String
  login_status : String
  login_code : String
  storage_status : String
  storage_value : String
  request_status : String
  request_body : String
  request_code : String
  request_case : Int
  request_base : String
  response_open : Bool
  toast_status : String
  location : String
  media : String
  request_error : String
} derive(Eq)

///|
pub enum Msg {
  StorageInput(String)
  Login
  Logout
  LoginSucceeded(String)
  LoginFailed(String)
  LoadStorage
  SaveStorage
  StorageLoaded(String)
  StorageSaved
  StorageFailed(String)
  LoadRequest
  RequestCase(Int)
  RequestBase(String)
  ToggleResponse
  RequestLoaded(Int, String)
  RequestFailed(String)
  ShowToast
  ToastShown
  ToastFailed(String)
  Locate
  LocationLoaded(String)
  LocationFailed(String)
  ChooseMedia
  MediaChosen(String)
  MediaFailed(String)
}

///|
fn initial_model() -> Model {
  {
    storage_input: "Minimoon",
    login_status: "idle",
    login_code: "",
    storage_status: "idle",
    storage_value: "",
    request_status: "idle",
    request_body: "",
    request_code: "",
    request_case: 0,
    request_base: @application.echo_base_url(),
    response_open: false,
    toast_status: "idle",
    location: "",
    media: "",
    request_error: "",
  }
}

///|
fn update(
  model : Model,
  msg : Msg,
  emit : @minimoon.Emit[Msg],
) -> (Model, @minimoon.Cmd) {
  match msg {
    StorageInput(value) => @minimoon.no_cmd({ ..model, storage_input: value, })
    Login =>
      @minimoon.with_cmd(
        { ..model, login_status: "pending", login_code: "", },
        @minimoon.login(
          emit.map(result => {
            match result {
              Ok(login) => LoginSucceeded(login.code)
              Err(error) => LoginFailed(error.message)
            }
          }),
        ),
      )
    Logout =>
      @minimoon.no_cmd({ ..model, login_status: "idle", login_code: "", })
    LoginSucceeded(code) =>
      @minimoon.no_cmd({ ..model, login_status: "success", login_code: code, })
    LoginFailed(error) =>
      @minimoon.no_cmd({ ..model, login_status: "failed: " + error, })
    LoadStorage =>
      @minimoon.with_cmd(
        { ..model, storage_status: "loading", },
        @minimoon.get_storage(
          "minimoon-conformance-platform",
          emit.map(result => {
            match result {
              Ok(storage) =>
                StorageLoaded(
                  match storage.data {
                    String(value) => value
                    value => value.stringify()
                  },
                )
              Err(error) => StorageFailed(error.message)
            }
          }),
        ),
      )
    SaveStorage =>
      @minimoon.with_cmd(
        { ..model, storage_status: "saving", },
        @minimoon.set_storage(
          "minimoon-conformance-platform",
          Json::string(model.storage_input),
          emit.map(result => {
            match result {
              Ok(_) => StorageSaved
              Err(error) => StorageFailed(error.message)
            }
          }),
        ),
      )
    StorageLoaded(value) =>
      @minimoon.no_cmd({
        ..model,
        storage_status: "loaded",
        storage_value: value,
      })
    StorageSaved => @minimoon.no_cmd({ ..model, storage_status: "saved", })
    StorageFailed(error) =>
      @minimoon.no_cmd({ ..model, storage_status: "failed: " + error, })
    RequestCase(index) => @minimoon.no_cmd({ ..model, request_case: index, })
    RequestBase(base) => @minimoon.no_cmd({ ..model, request_base: base, })
    ToggleResponse =>
      @minimoon.no_cmd({ ..model, response_open: !model.response_open, })
    LoadRequest =>
      @minimoon.with_cmd(
        {
          ..model,
          request_status: "loading",
          request_body: "",
          request_code: "",
          request_error: "",
        },
        http_case(
          model.request_case,
          model.request_base,
          emit.map(result => {
            match result {
              Ok(response) =>
                RequestLoaded(response.status_code, http_summary(response))
              Err(error) => RequestFailed(error.message)
            }
          }),
        ),
      )
    RequestLoaded(code, body) =>
      @minimoon.no_cmd({
        ..model,
        request_status: "loaded",
        request_body: body,
        request_code: code.to_string(),
      })
    RequestFailed(error) =>
      @minimoon.no_cmd({
        ..model,
        request_status: "failed",
        request_error: error,
      })
    ShowToast =>
      @minimoon.with_cmd(
        { ..model, toast_status: "showing", },
        @minimoon.show_toast(
          "Minimoon 提示",
          emit.map(result => {
            match result {
              Ok(_) => ToastShown
              Err(error) => ToastFailed(error.message)
            }
          }),
        ),
      )
    ToastShown => @minimoon.no_cmd({ ..model, toast_status: "shown", })
    ToastFailed(error) =>
      @minimoon.no_cmd({ ..model, toast_status: "failed: " + error, })
    Locate =>
      @minimoon.with_cmd(
        { ..model, location: "locating", },
        @minimoon.get_location(
          emit.map(result => {
            match result {
              Ok(location) =>
                LocationLoaded(
                  location.latitude.to_string() +
                  "," +
                  location.longitude.to_string(),
                )
              Err(error) => LocationFailed(error.message)
            }
          }),
        ),
      )
    LocationLoaded(value) => @minimoon.no_cmd({ ..model, location: value, })
    LocationFailed(error) =>
      @minimoon.no_cmd({ ..model, location: "failed: " + error, })
    ChooseMedia =>
      @minimoon.with_cmd(
        { ..model, media: "choosing", },
        @minimoon.choose_media(
          emit.map(result => {
            match result {
              Ok(media) =>
                MediaChosen(
                  match media.temp_files.get(0) {
                    Some(file) => file.temp_file_path
                    None => ""
                  },
                )
              Err(error) => MediaFailed(error.message)
            }
          }),
        ),
      )
    MediaChosen(value) => @minimoon.no_cmd({ ..model, media: value, })
    MediaFailed(error) =>
      @minimoon.no_cmd({ ..model, media: "failed: " + error, })
  }
}

///|
fn action(
  emit : @minimoon.Emit[Msg],
  key : String,
  msg : Msg,
  label : String,
) -> @minimoon.Node {
  @minimoon.button(
    class="demo-action",
    event_key="platform/" + key,
    on_tap=emit(msg),
    label,
  )
}

///|
fn output(section : String, value : String) -> @minimoon.Node {
  @minimoon.p(class="demo-output", data_section=section, value)
}

///|
fn view(model : Model, emit : @minimoon.Emit[Msg]) -> @minimoon.Node {
  @minimoon.div(class="demo-stack", [
    @shell.card("登录凭证", section="platform-login", [
      @minimoon.p("清除仅影响显示，不注销登录。"),
      @minimoon.div(class="demo-actions", [
        action(emit, "login", Login, "获取凭证"),
        action(emit, "clear-login", Logout, "清除显示"),
      ]),
      output(
        "session-state",
        "login: " + model.login_status + " · code: " + model.login_code,
      ),
    ]),
    @shell.card("本地存储", section="platform-storage", [
      @minimoon.input(
        class="demo-input",
        value=model.storage_input,
        placeholder="要保存的文本",
        on_input=emit.map(value => StorageInput(value)),
        event_key="platform/storage-input",
      ),
      @minimoon.div(class="demo-actions", [
        action(emit, "save-storage", SaveStorage, "保存文本"),
        action(emit, "load-storage", LoadStorage, "读取文本"),
      ]),
      output(
        "storage-state",
        "storage: " + model.storage_status + " · value: " + model.storage_value,
      ),
    ]),
    @shell.card("系统提示", section="platform-toast", [
      action(emit, "toast", ShowToast, "显示提示"),
      output("toast-state", "toast: " + model.toast_status),
    ]),
    @shell.card("位置", section="platform-location", [
      action(emit, "location", Locate, "获取位置"),
      output("location-state", "location: " + model.location),
    ]),
    @shell.card("媒体", section="platform-media", [
      action(emit, "media", ChooseMedia, "选择媒体"),
      output("media-state", "media: " + model.media),
    ]),
    @shell.card("HTTP 请求", section="platform-http", [
      @minimoon.p(
        class="demo-muted",
        "合成数据仅做公共 echo，不持久保存。",
      ),
      @minimoon.input(
        class="demo-input",
        value=model.request_base,
        on_input=emit.map(value => RequestBase(value)),
        event_key="platform/http-base",
        placeholder="公共 HTTPS echo API 地址",
      ),
      @minimoon.picker_selector(
        options=http_cases(),
        selected=model.request_case,
        on_change=emit.map(value => RequestCase(value)),
        event_key="platform/http-case",
        "HTTP scenario: " +
        http_cases().get(model.request_case).unwrap_or("GET"),
      ),
      action(emit, "request", LoadRequest, "发送请求"),
      output(
        "request-output",
        "request: " + model.request_status + " · HTTP " + model.request_code,
      ),
      if model.request_status == "failed" {
        output("request-error", model.request_error)
      } else {
        @minimoon.nothing()
      },
      action(
        emit,
        "toggle-response",
        ToggleResponse,
        if model.response_open {
          "收起响应详情"
        } else {
          "查看响应详情"
        },
      ),
      if model.response_open {
        output("http-response-detail", model.request_body)
      } else {
        @minimoon.nothing()
      },
    ]),
    @shell.card(
      "请求离开页面后会怎样？",
      section="platform-lifecycle-entry",
      [
        @minimoon.p("对照隐藏保留、卸载取消与 App 继续。"),
        @minimoon.navigator(
          target=@minimoon.route("pages/request_lifecycle/request_lifecycle").with_query([
              @minimoon.query("name", "Platform"),
            ],
          ),
          class="demo-action",
          "请求生命周期实验",
        ),
      ],
    ),
  ])
}

///|
pub fn program(_deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="platform",
    route=@minimoon.route("pages/platform/platform"),
    title="平台",
    capabilities=[
      @minimoon.NavigateBack,
      @minimoon.SwitchTab,
      @minimoon.Login,
      @minimoon.GetStorage,
      @minimoon.SetStorage,
      @minimoon.Request,
      @minimoon.ShowToast,
      @minimoon.GetLocation,
      @minimoon.ChooseMedia,
    ],
    build=context => {
      let (model, emit) = @minimoon.create_state(initial_model(), update=(
        current,
        message,
        emit,
      ) => update(current, message, emit))
      let notes = @shell.technical_notes("platform", [
        "HTTP 400/500 是有效响应，不是网络失败。", "开发绕过不证明生产可用。",
        "切 Tab 保留状态；卸载请进入生命周期实验。",
      ])
      model
      .view(model => view(model, emit))
      .view3(context.layout(), notes, (content, layout, notes) => {
        @shell.frame(layout, "平台", "platform-page", [
          @shell.hero(
            "连接微信与网络", "选择能力，操作后就地查看结果",
            "platform-intro",
          ),
          @minimoon.div(class="demo-body", [
            content,
            @minimoon.button(
              class="demo-action",
              event_key="platform/back",
              on_tap=@minimoon.navigate_back_or(
                fallback=@minimoon.route("pages/more/more"),
              ),
              "返回",
            ),
            notes,
          ]),
        ])
      })
    },
  )
}
