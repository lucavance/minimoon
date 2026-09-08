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
fn action_row(
  section : String,
  wrap : Bool,
  gap : String,
  children : Array[@minimoon.Node],
) -> @minimoon.Node {
  let class_name = if wrap {
    "flex flex-wrap items-center justify-center gap-[10rpx]"
  } else {
    "flex items-center justify-center gap-[6rpx]"
  }
  let wrap_value = if wrap { "wrap" } else { "nowrap" }
  @minimoon.div(
    class=class_name,
    data_section=section,
    style="display: flex; flex-direction: row; flex-wrap: " +
      wrap_value +
      "; align-items: center; justify-content: center; gap: " +
      gap +
      "; width: 100%; box-sizing: border-box;",
    children,
  )
}

///|
fn action(
  emit : @minimoon.Emit[Msg],
  key : String,
  msg : Msg,
  label : String,
  min_width : String,
  color : String,
) -> @minimoon.Node {
  @minimoon.button(
    on_tap=event(emit, key, msg),
    event_key=key,
    class=min_width +
      " rounded-[8rpx] " +
      color +
      " px-[14rpx] py-[8rpx] text-[24rpx] leading-none text-white",
    style="margin: 0; display: flex; align-items: center; justify-content: center; box-sizing: border-box; line-height: 1; min-height: 0; flex-shrink: 0;",
    label,
  )
}

///|
fn status_panel(
  section : String,
  children : Array[@minimoon.Node],
) -> @minimoon.Node {
  @minimoon.div(
    class="flex min-h-[48rpx] min-w-[320rpx] items-center rounded-[10rpx] bg-white px-[18rpx] py-[8rpx] text-[24rpx] text-slate-700 whitespace-normal break-all",
    data_section=section,
    style="width: 100%; max-width: calc(100vw - 48rpx); word-break: break-all; overflow-wrap: anywhere; white-space: pre-wrap; line-height: 1.35;",
    children,
  )
}

///|
fn request_panel(model : Model) -> @minimoon.Node {
  @minimoon.div(
    class="flex min-h-[48rpx] min-w-[320rpx] flex-col rounded-[10rpx] bg-white px-[18rpx] py-[8rpx] text-[24rpx] text-slate-700 whitespace-normal break-all",
    data_section="request-output",
    style="width: 100%; max-width: calc(100vw - 48rpx); align-items: stretch; gap: 6rpx; word-break: break-all; overflow-wrap: anywhere; white-space: pre-wrap; line-height: 1.35;",
    [
      @minimoon.p(class="block font-semibold", [
        @minimoon.text(
          "request: " + model.request_status + " · HTTP " + model.request_code,
        ),
      ]),
      @minimoon.p(
        class="block text-slate-600",
        style="max-width: calc(100vw - 84rpx); word-break: break-all; overflow-wrap: anywhere; white-space: pre-wrap; line-height: 1.35;",
        [@minimoon.text(model.request_body)],
      ),
    ],
  )
}

///|
fn view(
  model : Model,
  emit : @minimoon.Emit[Msg],
  input_name : String,
  shared_panel : @minimoon.Node,
) -> @minimoon.Node {
  let name = if model.name == "" { input_name } else { model.name }
  @minimoon.scroll_view(
    class="box-border h-[100vh] bg-slate-100 px-[24rpx] pb-[32rpx] pt-[72rpx]",
    style="display: flex; flex-direction: column; align-items: center; gap: 12rpx;",
    scroll_y=true,
    data_section="home-page",
    [
      @minimoon.div(
        class="rounded-[16rpx] bg-slate-700 px-[24rpx] py-[20rpx] text-white",
        data_section="home-intro",
        style="width: 100%; max-width: calc(100vw - 48rpx); box-sizing: border-box;",
        [
          @minimoon.p(
            class="text-[24rpx] font-semibold text-white",
            "01 · HOST CAPABILITIES",
          ),
          @minimoon.h1(
            class="mt-[8rpx] text-[36rpx] font-semibold text-white",
            "能力控制台",
          ),
          @minimoon.p(
            class="mt-[8rpx] text-[24rpx] text-white",
            style="opacity: 0.78;",
            "Capability Console · state, wx.* commands, and navigation",
          ),
          @minimoon.div(class="mt-[16rpx]", [
            action(
              emit,
              "home/back-studio",
              BackToStudio,
              "返回 Studio / Back",
              "min-w-[200rpx]",
              "bg-indigo-600",
            ),
          ]),
        ],
      ),
      @minimoon.p(
        class="text-[24rpx] font-semibold text-slate-500",
        "STATE INPUT / 状态输入",
      ),
      @minimoon.input(
        value=name,
        on_input=emit.map(value => NameInput(value)),
        event_key="home/name",
        placeholder="Name from ?name= query",
        class="min-w-[320rpx] rounded-[10rpx] bg-white px-[18rpx] py-[12rpx] text-[26rpx]",
      ),
      status_panel("home-controls", [@minimoon.text("hello: " + name)]),
      @minimoon.h1(
        class="flex h-[112rpx] min-w-[184rpx] items-center justify-center rounded-[12rpx] border border-sky-200 bg-white px-[32rpx] text-[64rpx] font-semibold leading-none text-sky-700",
        model.count.to_string(),
      ),
      action_row("home-controls", false, "6rpx", [
        action(emit, "home/dec", Dec, "-1", "min-w-[84rpx]", "bg-sky-600"),
        action(emit, "home/inc", Inc, "+1", "min-w-[84rpx]", "bg-sky-600"),
        action(
          emit,
          "home/reset",
          Reset,
          "Reset",
          "min-w-[112rpx]",
          "bg-emerald-600",
        ),
      ]),
      action_row("session-controls", false, "6rpx", [
        action(
          emit,
          "home/login",
          Login,
          "Login",
          "min-w-[112rpx]",
          "bg-indigo-600",
        ),
        action(
          emit,
          "home/logout",
          Logout,
          "Logout",
          "min-w-[120rpx]",
          "bg-zinc-700",
        ),
      ]),
      @minimoon.p(
        class="text-[24rpx] font-semibold text-slate-500",
        "DECLARED WX.* / 已声明主机能力",
      ),
      action_row("capability-controls", true, "10rpx", [
        action(
          emit,
          "home/load-storage",
          LoadStorage,
          "Storage",
          "min-w-[128rpx]",
          "bg-cyan-600",
        ),
        action(
          emit,
          "home/save-storage",
          SaveStorage,
          "Save",
          "min-w-[112rpx]",
          "bg-teal-600",
        ),
        action(
          emit,
          "home/request",
          LoadRequest,
          "Request",
          "min-w-[128rpx]",
          "bg-rose-600",
        ),
        action(
          emit,
          "home/toast",
          ShowToast,
          "Toast",
          "min-w-[112rpx]",
          "bg-orange-600",
        ),
        action(
          emit,
          "home/location",
          Locate,
          "Locate",
          "min-w-[120rpx]",
          "bg-slate-700",
        ),
        action(
          emit,
          "home/media",
          ChooseMedia,
          "Media",
          "min-w-[112rpx]",
          "bg-violet-600",
        ),
      ]),
      @minimoon.p(
        class="text-[24rpx] font-semibold text-slate-500",
        "ROUTING / 页面导航",
      ),
      action_row("navigation-controls", true, "10rpx", [
        action(
          emit,
          "home/open-lab",
          OpenLab,
          "Open Lab",
          "min-w-[160rpx]",
          "bg-violet-700",
        ),
        action(
          emit,
          "home/open-details",
          OpenDetails,
          "Open details",
          "min-w-[200rpx]",
          "bg-blue-700",
        ),
        action(
          emit,
          "home/redirect-details",
          ReplaceDetails,
          "Redirect",
          "min-w-[132rpx]",
          "bg-fuchsia-600",
        ),
      ]),
      status_panel("session-state", [
        @minimoon.text("login: " + model.login_status),
        @minimoon.text(" · "),
        @minimoon.text("code: " + model.login_code),
      ]),
      status_panel("storage-state", [
        @minimoon.text("storage: " + model.storage_status),
        @minimoon.text(" · "),
        @minimoon.text("value: " + model.storage_value),
      ]),
      @minimoon.input(
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
      request_panel(model),
      status_panel("toast-state", [
        @minimoon.text("toast: " + model.toast_status),
      ]),
      status_panel("location-state", [
        @minimoon.text("location: " + model.location),
      ]),
      status_panel("media-state", [@minimoon.text("media: " + model.media)]),
      status_panel("lifecycle-state", [
        @minimoon.text("visible: " + model.visible.to_string()),
      ]),
      status_panel("error-state", [@minimoon.text("error: " + model.error)]),
      shared_panel,
    ],
  )
}

///|
fn app(
  context : @minimoon.PageContext,
  name : String,
  deps : @application.Deps,
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
  model.view2(@application.panel(context, deps), (current, shared_panel) => {
    view(current, emit, name, shared_panel)
  })
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
    capabilities=[
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
    ],
    decode_input~,
    build=(context, input) => app(context, input, deps),
  )
}
