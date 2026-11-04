///|
#derive(Eq, Debug)
pub(all) enum ResourceContent {
  Text(String)
  Binary(Bytes)
}

///|
/// A build asset. Text uses SVG/txt paths and binary assets use PNG paths.
/// Paths are relative to dist and must live below assets/.
#derive(Eq, Debug)
pub(all) struct ResourceAsset {
  path : String
  content : ResourceContent
}

///|
/// Build-time resources, never included in the application runtime implicitly.
#derive(Eq, Debug)
pub(all) struct ResourceBundle {
  id : String
  version : String
  wxss : String
  assets : Array[ResourceAsset]
}

///|
/// Serialize a typed provider result for the native build probe.
pub fn encode(bundle : ResourceBundle) -> String {
  Json::object({
    "id": Json::string(bundle.id),
    "version": Json::string(bundle.version),
    "wxss": Json::string(bundle.wxss),
    "assets": Json::array(
      bundle.assets.map(asset => {
        let (encoding, content) = match asset.content {
          Text(text) => ("utf8", text)
          Binary(bytes) => ("base64", @base64.encode(bytes))
        }
        Json::object({
          "path": Json::string(asset.path),
          "encoding": Json::string(encoding),
          "content": Json::string(content),
        })
      }),
    ),
  }).stringify()
}
