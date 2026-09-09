///|
pub struct Model {
  count : Int
  name : String
  visible : Bool
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
  error : String
} derive(Eq)

///|
pub enum Msg {
  Inc
  Dec
  Reset
  NameInput(String)
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
  OpenLab
  OpenDetails
  ReplaceDetails
  BackToStudio
  PageShown
  PageHidden
}

///|
fn initial_model() -> Model {
  {
    count: 0,
    name: "",
    visible: false,
    login_status: "idle",
    login_code: "",
    storage_status: "idle",
    storage_value: "",
    request_status: "idle",
    request_body: "",
    request_code: "",
    request_case: 0,
    request_base: "https://httpbingo.org",
    response_open: false,
    toast_status: "idle",
    location: "",
    media: "",
    error: "",
  }
}

///|
fn update(
  model : Model,
  msg : Msg,
  emit : @minimoon.Emit[Msg],
) -> (Model, @minimoon.Cmd) {
  match msg {
    Inc => @minimoon.no_cmd({ ..model, count: model.count + 1, })
    Dec => @minimoon.no_cmd({ ..model, count: model.count - 1, })
    Reset => @minimoon.no_cmd({ ..model, count: 0, })
    NameInput(name) => @minimoon.no_cmd({ ..model, name, })
    Login =>
      @minimoon.with_cmd(
        { ..model, login_status: "pending", login_code: "", error: "", },
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
      @minimoon.no_cmd({
        ..model,
        login_status: "idle",
        login_code: "",
        error: "",
      })
    LoginSucceeded(code) =>
      @minimoon.no_cmd({ ..model, login_status: "success", login_code: code, })
    LoginFailed(error) =>
      @minimoon.no_cmd({ ..model, login_status: "failed", error, })
    LoadStorage =>
      @minimoon.with_cmd(
        { ..model, storage_status: "loading", error: "", },
        @minimoon.get_storage(
          "minimoon-conformance-home",
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
        { ..model, storage_status: "saving", error: "", },
        @minimoon.set_storage(
          "minimoon-conformance-home",
          Json::string(model.count.to_string()),
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
      @minimoon.no_cmd({ ..model, storage_status: "failed", error, })
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
          error: "",
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
      @minimoon.no_cmd({ ..model, request_status: "failed", error, })
    ShowToast =>
      @minimoon.with_cmd(
        { ..model, toast_status: "showing", error: "", },
        @minimoon.show_toast(
          "Count: " + model.count.to_string(),
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
      @minimoon.no_cmd({ ..model, toast_status: "failed", error, })
    Locate =>
      @minimoon.with_cmd(
        { ..model, location: "locating", error: "", },
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
    LocationFailed(error) => @minimoon.no_cmd({ ..model, location: "", error, })
    ChooseMedia =>
      @minimoon.with_cmd(
        { ..model, media: "choosing", error: "", },
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
    MediaFailed(error) => @minimoon.no_cmd({ ..model, media: "", error, })
    OpenLab =>
      @minimoon.with_cmd(
        model,
        @minimoon.navigate_to(@minimoon.route("pages/lab/lab")),
      )
    OpenDetails =>
      @minimoon.with_cmd(
        model,
        @minimoon.navigate_to(
          @minimoon.route("pages/details/details").with_query([
            @minimoon.query("from", "home"),
          ]),
        ),
      )
    ReplaceDetails =>
      @minimoon.with_cmd(
        model,
        @minimoon.redirect_to(
          @minimoon.route("pages/details/details").with_query([
            @minimoon.query("from", "redirect"),
          ]),
        ),
      )
    BackToStudio =>
      @minimoon.with_cmd(
        model,
        @minimoon.navigate_back_or(
          fallback=@minimoon.route("pages/showcase/showcase"),
        ),
      )
    PageShown => @minimoon.no_cmd({ ..model, visible: true, })
    PageHidden => @minimoon.no_cmd({ ..model, visible: false, })
  }
}

///|
fn event(emit : @minimoon.Emit[Msg], key : String, msg : Msg) -> @minimoon.Cmd {
  let _ = key
  emit(msg)
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
    event_key=key,
    on_tap=event(emit, key, msg),
    label,
  )
}

///|
fn status_panel(section : String, text : String) -> @minimoon.Node {
  @minimoon.p(class="demo-output", data_section=section, text)
}

///|
fn view(
  model : Model,
  emit : @minimoon.Emit[Msg],
  input_name : String,
  shared_panel : @minimoon.Node,
  layout : @minimoon.PageLayout,
  notes : @minimoon.Node,
  concise : Bool,
) -> @minimoon.Node {
  let name = if model.name == "" { input_name } else { model.name }
  @shell.frame(layout, "能力", "home-page", [
    @shell.hero("能力控制台", "Typed state · Native wx.*", "home-intro"),
    @minimoon.div(class="demo-body", [
      @shell.card("输入与状态", section="home-controls", [
        @minimoon.input(
          value=name,
          on_input=emit.map(value => NameInput(value)),
          event_key="home/name",
          placeholder="Name from ?name= query",
          class="demo-input",
        ),
        status_panel("home-controls", "hello: " + name),
        @minimoon.h1(class="demo-value", model.count.to_string()),
        @minimoon.div(class="demo-actions", [
          action(emit, "home/dec", Dec, "−1"),
          action(emit, "home/inc", Inc, "+1"),
          action(emit, "home/reset", Reset, "Reset"),
        ]),
      ]),
      @shell.card("原生能力", [
        @minimoon.div(class="demo-actions", data_section="session-controls", [
          action(emit, "home/login", Login, "Login"),
          action(emit, "home/logout", Logout, "Logout"),
        ]),
        @minimoon.div(
          class="demo-actions",
          data_section="capability-controls",
          [
            action(emit, "home/load-storage", LoadStorage, "Storage"),
            action(emit, "home/save-storage", SaveStorage, "Save"),
            action(emit, "home/toast", ShowToast, "Toast"),
            action(emit, "home/location", Locate, "Locate"),
            action(emit, "home/media", ChooseMedia, "Media"),
          ],
        ),
        status_panel(
          "session-state",
          "login: " + model.login_status + " · code: " + model.login_code,
        ),
        status_panel(
          "storage-state",
          "storage: " +
          model.storage_status +
          " · value: " +
          model.storage_value,
        ),
        status_panel("toast-state", "toast: " + model.toast_status),
        status_panel("location-state", "location: " + model.location),
        status_panel("media-state", "media: " + model.media),
      ]),
      @shell.card("HTTP 请求", [
        @minimoon.p(
          class="demo-muted",
          "使用合成数据访问公开 echo API，不是持久保存。",
        ),
        @minimoon.input(
          class="demo-input",
          value=model.request_base,
          on_input=emit.map(value => RequestBase(value)),
          event_key="home/http-base",
          placeholder="HTTPS httpbingo-compatible base URL",
        ),
        @minimoon.picker_selector(
          options=http_cases(),
          selected=model.request_case,
          on_change=emit.map(value => RequestCase(value)),
          event_key="home/http-case",
          "HTTP scenario: " +
          http_cases().get(model.request_case).unwrap_or("GET"),
        ),
        action(emit, "home/request", LoadRequest, "Request"),
        @minimoon.div(
          data_section="request-output",
          class="demo-output",
          style="overflow-wrap: anywhere;",
          [
            @minimoon.p(
              "request: " +
              model.request_status +
              " · HTTP " +
              model.request_code,
            ),
            if concise {
              action(
                emit,
                "home/toggle-response",
                ToggleResponse,
                if model.response_open {
                  "收起响应详情"
                } else {
                  "查看响应详情"
                },
              )
            } else {
              @minimoon.nothing()
            },
            if !concise || model.response_open {
              @minimoon.p(
                data_section="http-response-detail",
                model.request_body,
              )
            } else {
              @minimoon.nothing()
            },
          ],
        ),
      ]),
      @shell.card("真实页面栈", section="navigation-controls", [
        @minimoon.div(class="demo-actions", [
          action(emit, "home/open-lab", OpenLab, "Open Lab"),
          action(emit, "home/open-details", OpenDetails, "Open details"),
          action(emit, "home/redirect-details", ReplaceDetails, "Redirect"),
          action(emit, "home/back-studio", BackToStudio, "返回首页 / Back"),
        ]),
        status_panel("lifecycle-state", "visible: " + model.visible.to_string()),
        status_panel("error-state", "error: " + model.error),
      ]),
      shared_panel,
      notes,
    ]),
  ])
}

///|
pub fn scene(
  context : @minimoon.PageContext,
  name : String,
  deps : @application.Deps,
  concise? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  let (model, emit) = @minimoon.create_state(
    initial_model(),
    update=(current, message, emit) => update(current, message, emit),
    subscriptions=(_, emit) => {
      @minimoon.Sub::batch([
        context.on_show(emit(PageShown)),
        context.on_hide(emit(PageHidden)),
      ])
    },
  )
  let notes = @shell.technical_notes("home", [
    "HTTP 400/500 remain loaded raw responses; timeout is failed.", "NavigateTo hides this page; RedirectTo unloads it and cancels page-owned HTTP.",
    "App-owned HTTP survives page unload. Developer domain bypass is not production readiness.",
  ])
  model.view4(@application.panel(context, deps), context.layout(), notes, (
    current,
    shared_panel,
    layout,
    notes,
  ) => view(current, emit, name, shared_panel, layout, notes, concise))
}

///|
fn decode_input(
  fields : Map[String, String],
) -> Result[String, @minimoon.DecodeError] {
  Ok(fields.get("name").unwrap_or("Minimoon"))
}

///|
pub fn program(deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page_with_input(
    id="home",
    route=@minimoon.route("pages/home/home"),
    title="Minimoon Home",
    preview_input=() => "Minimoon",
    capabilities=capabilities(),
    decode_input~,
    build=(context, input) => scene(context, input, deps),
  )
}

///|
pub fn capabilities() -> Array[@minimoon.Capability] {
  [
    @minimoon.Login,
    @minimoon.GetStorage,
    @minimoon.SetStorage,
    @minimoon.Request,
    @minimoon.ShowToast,
    @minimoon.GetLocation,
    @minimoon.ChooseMedia,
    @minimoon.NavigateTo,
    @minimoon.RedirectTo,
    @minimoon.NavigateBack,
    @minimoon.SwitchTab,
  ]
}
