///|
pub struct LoginResult {
  code : String
}

///|
pub struct StorageResult {
  data : Json
}

///|
pub struct RequestResult {
  status_code : Int
  data : Json
  headers : Map[String, String]
  cookies : Array[String]
}

///|
pub struct LocationResult {
  latitude : Double
  longitude : Double
  speed : Double?
  accuracy : Double?
  altitude : Double?
  vertical_accuracy : Double?
  horizontal_accuracy : Double?
}

///|
pub struct MediaFile {
  temp_file_path : String
  size : Int?
  file_type : String?
  width : Int?
  height : Int?
  duration : Double?
  thumb_temp_file_path : String?
}

///|
pub struct ChooseMediaResult {
  temp_files : Array[MediaFile]
  media_type : String?
}

///|
pub struct PaymentParams {
  time_stamp : String
  nonce_str : String
  package_value : String
  sign_type : String
  pay_sign : String
}

///|
pub fn PaymentParams::new(
  time_stamp~ : String,
  nonce_str~ : String,
  package_value~ : String,
  sign_type~ : String,
  pay_sign~ : String,
) -> PaymentParams {
  { time_stamp, nonce_str, package_value, sign_type, pay_sign, }
}

///|
pub(all) enum Capability {
  Login
  GetStorage
  SetStorage
  Request
  ShowToast
  GetLocation
  ChooseMedia
  RequestPayment
  NavigateTo
  RedirectTo
  NavigateBack
} derive(Debug, Eq)

///|
pub fn Capability::name(self : Capability) -> String {
  match self {
    Login => "wx.login"
    GetStorage => "wx.getStorage"
    SetStorage => "wx.setStorage"
    Request => "wx.request"
    ShowToast => "wx.showToast"
    GetLocation => "wx.getLocation"
    ChooseMedia => "wx.chooseMedia"
    RequestPayment => "wx.requestPayment"
    NavigateTo => "wx.navigateTo"
    RedirectTo => "wx.redirectTo"
    NavigateBack => "wx.navigateBack"
  }
}

///|
fn Capability::to_core(self : Capability) -> @renderer.MiniappCapability {
  @renderer.miniapp_capability(self.name())
}

///|
pub(all) enum HostErrorKind {
  Failed
  Unavailable
  InvalidPayload
} derive(Debug, Eq)

///|
pub struct HostError {
  capability : Capability
  kind : HostErrorKind
  message : String
  code : String?
  raw : Json
}

///|
fn error_kind(phase : String) -> HostErrorKind {
  match phase {
    "unavailable" => Unavailable
    "invalid_payload" => InvalidPayload
    _ => Failed
  }
}

///|
fn raw_json(raw : String) -> Json {
  @json.parse(raw) catch {
    _ => Json::null()
  }
}

///|
fn json_code(raw : Json) -> String? {
  match raw {
    Object(fields) =>
      match fields.get("errCode") {
        Some(String(value)) => Some(value)
        Some(Number(value, ..)) => Some(value.to_string())
        _ => None
      }
    _ => None
  }
}

///|
fn host_error(
  capability : Capability,
  kind : HostErrorKind,
  message : String,
  raw : Json,
) -> HostError {
  { capability, kind, message, code: json_code(raw), raw, }
}

///|
fn invalid_payload(
  capability : Capability,
  message : String,
  raw : Json,
) -> HostError {
  host_error(capability, InvalidPayload, message, raw)
}

///|
fn[A] host_effect(
  capability : Capability,
  payload : Json,
  decode : (Json) -> Result[A, HostError],
  resolve : Emit[Result[A, HostError]],
) -> Cmd {
  Cmd(
    @val.host_effect(capability.name(), payload.stringify(), outcome => {
      match outcome {
        @val.HostOk(raw) => {
          let parsed : Json? = Some(@json.parse(raw)) catch { _ => None }
          resolve(
            match parsed {
              Some(value) => decode(value)
              None =>
                Err(
                  invalid_payload(
                    capability,
                    "host success payload is not valid JSON",
                    Json::string(raw),
                  ),
                )
            },
          ).0
        }
        @val.HostErr(phase, message, raw) => {
          let value = raw_json(raw)
          resolve(
            Err(host_error(capability, error_kind(phase), message, value)),
          ).0
        }
      }
    }),
  )
}

///|
fn object_result(
  capability : Capability,
  value : Json,
) -> Result[Map[String, Json], HostError] {
  match value {
    Object(fields) => Ok(fields)
    _ =>
      Err(invalid_payload(capability, "host result must be an object", value))
  }
}

///|
fn string_field(fields : Map[String, Json], name : String) -> String? {
  match fields.get(name) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn number_field(fields : Map[String, Json], name : String) -> Double? {
  match fields.get(name) {
    Some(Number(value, ..)) => Some(value)
    _ => None
  }
}

///|
fn host_int32(value : Double) -> Int? {
  if value < 0.0 || value > 2147483647.0 {
    return None
  }
  let integer = value.to_int()
  if integer.to_double() == value {
    Some(integer)
  } else {
    None
  }
}

///|
fn decode_login(value : Json) -> Result[LoginResult, HostError] {
  let capability = Login
  match object_result(capability, value) {
    Err(error) => Err(error)
    Ok(fields) =>
      match string_field(fields, "code") {
        Some(code) if code != "" => Ok({ code, })
        _ =>
          Err(
            invalid_payload(
              capability, "wx.login result.code is missing", value,
            ),
          )
      }
  }
}

///|
fn decode_storage(value : Json) -> Result[StorageResult, HostError] {
  let capability = GetStorage
  match object_result(capability, value) {
    Err(error) => Err(error)
    Ok(fields) =>
      match fields.get("data") {
        Some(data) => Ok({ data, })
        None =>
          Err(
            invalid_payload(
              capability, "wx.getStorage result.data is missing", value,
            ),
          )
      }
  }
}

///|
fn headers(fields : Map[String, Json]) -> Map[String, String] {
  let output : Map[String, String] = Map([])
  match fields.get("header") {
    Some(Object(values)) =>
      for name, value in values {
        output[name] = match value {
          String(value) => value
          value => value.stringify()
        }
      }
    _ => ()
  }
  output
}

///|
fn cookies(fields : Map[String, Json]) -> Array[String] {
  match fields.get("cookies") {
    Some(Array(values)) =>
      values.filter_map(value => {
        match value {
          String(value) => Some(value)
          _ => None
        }
      })
    _ => []
  }
}

///|
fn decode_request(value : Json) -> Result[RequestResult, HostError] {
  let capability = Request
  match object_result(capability, value) {
    Err(error) => Err(error)
    Ok(fields) =>
      match fields.get("statusCode") {
        Some(Number(status, ..)) =>
          match host_int32(status) {
            Some(status_code) =>
              Ok({
                status_code,
                data: fields.get("data").unwrap_or(Json::null()),
                headers: headers(fields),
                cookies: cookies(fields),
              })
            None =>
              Err(
                invalid_payload(
                  capability, "wx.request result.statusCode must be an integer from 0 to 2147483647",
                  value,
                ),
              )
          }
        Some(_) =>
          Err(
            invalid_payload(
              capability, "wx.request result.statusCode must be an integer from 0 to 2147483647",
              value,
            ),
          )
        None =>
          Err(
            invalid_payload(
              capability, "wx.request result.statusCode is missing", value,
            ),
          )
      }
  }
}

///|
fn decode_location(value : Json) -> Result[LocationResult, HostError] {
  let capability = GetLocation
  match object_result(capability, value) {
    Err(error) => Err(error)
    Ok(fields) =>
      match
        (number_field(fields, "latitude"), number_field(fields, "longitude")) {
        (Some(latitude), Some(longitude)) =>
          Ok({
            latitude,
            longitude,
            speed: number_field(fields, "speed"),
            accuracy: number_field(fields, "accuracy"),
            altitude: number_field(fields, "altitude"),
            vertical_accuracy: number_field(fields, "verticalAccuracy"),
            horizontal_accuracy: number_field(fields, "horizontalAccuracy"),
          })
        _ =>
          Err(
            invalid_payload(
              capability, "wx.getLocation latitude/longitude are missing", value,
            ),
          )
      }
  }
}

///|
fn optional_media_int(
  fields : Map[String, Json],
  name : String,
) -> Result[Int?, Unit] {
  match fields.get(name) {
    None => Ok(None)
    Some(Number(value, ..)) =>
      match host_int32(value) {
        Some(integer) => Ok(Some(integer))
        None => Err(())
      }
    Some(_) => Err(())
  }
}

///|
fn media_file(value : Json) -> MediaFile? {
  match value {
    Object(fields) =>
      match string_field(fields, "tempFilePath") {
        Some(temp_file_path) => {
          let size = match optional_media_int(fields, "size") {
            Ok(value) => value
            Err(_) => return None
          }
          let width = match optional_media_int(fields, "width") {
            Ok(value) => value
            Err(_) => return None
          }
          let height = match optional_media_int(fields, "height") {
            Ok(value) => value
            Err(_) => return None
          }
          Some({
            temp_file_path,
            size,
            file_type: string_field(fields, "fileType"),
            width,
            height,
            duration: number_field(fields, "duration"),
            thumb_temp_file_path: string_field(fields, "thumbTempFilePath"),
          })
        }
        None => None
      }
    _ => None
  }
}

///|
fn decode_media(value : Json) -> Result[ChooseMediaResult, HostError] {
  let capability = ChooseMedia
  match object_result(capability, value) {
    Err(error) => Err(error)
    Ok(fields) =>
      match fields.get("tempFiles") {
        Some(Array(values)) => {
          let temp_files = values.filter_map(media_file)
          if temp_files.length() != values.length() {
            Err(
              invalid_payload(
                capability, "wx.chooseMedia tempFiles are malformed", value,
              ),
            )
          } else {
            Ok({ temp_files, media_type: string_field(fields, "type"), })
          }
        }
        _ =>
          Err(
            invalid_payload(
              capability, "wx.chooseMedia tempFiles are missing", value,
            ),
          )
      }
  }
}

///|
fn decode_unit(_value : Json) -> Result[Unit, HostError] {
  Ok(())
}

///|
pub fn login(resolve : Emit[Result[LoginResult, HostError]]) -> Cmd {
  host_effect(Login, Json::empty_object(), decode_login, resolve)
}

///|
pub fn get_storage(
  key : String,
  resolve : Emit[Result[StorageResult, HostError]],
) -> Cmd {
  host_effect(
    GetStorage,
    Json::object({ "key": Json::string(key) }),
    decode_storage,
    resolve,
  )
}

///|
pub fn set_storage(
  key : String,
  value : Json,
  resolve : Emit[Result[Unit, HostError]],
) -> Cmd {
  host_effect(
    SetStorage,
    Json::object({ "key": Json::string(key), "data": value }),
    decode_unit,
    resolve,
  )
}

///|
pub fn request(
  url : String,
  resolve : Emit[Result[RequestResult, HostError]],
) -> Cmd {
  host_effect(
    Request,
    Json::object({ "url": Json::string(url) }),
    decode_request,
    resolve,
  )
}

///|
pub fn show_toast(
  title : String,
  resolve : Emit[Result[Unit, HostError]],
) -> Cmd {
  host_effect(
    ShowToast,
    Json::object({ "title": Json::string(title) }),
    decode_unit,
    resolve,
  )
}

///|
pub fn get_location(resolve : Emit[Result[LocationResult, HostError]]) -> Cmd {
  host_effect(GetLocation, Json::empty_object(), decode_location, resolve)
}

///|
pub fn choose_media(
  resolve : Emit[Result[ChooseMediaResult, HostError]],
) -> Cmd {
  host_effect(ChooseMedia, Json::empty_object(), decode_media, resolve)
}

///|
pub fn request_payment(
  params : PaymentParams,
  resolve : Emit[Result[Unit, HostError]],
) -> Cmd {
  host_effect(
    RequestPayment,
    Json::object({
      "timeStamp": Json::string(params.time_stamp),
      "nonceStr": Json::string(params.nonce_str),
      "package": Json::string(params.package_value),
      "signType": Json::string(params.sign_type),
      "paySign": Json::string(params.pay_sign),
    }),
    decode_unit,
    resolve,
  )
}

///|
pub fn navigate_to(target : Route) -> Cmd {
  Cmd(@val.navigate_to(target.url()))
}

///|
pub fn redirect_to(target : Route) -> Cmd {
  Cmd(@val.redirect_to(target.url()))
}

///|
pub fn navigate_back(delta? : Int = 1) -> Cmd {
  Cmd(@val.navigate_back(delta))
}

///|
pub fn navigate_back_or(fallback~ : Route, delta? : Int = 1) -> Cmd {
  Cmd(@val.navigate_back_or_redirect(delta, fallback.url()))
}
