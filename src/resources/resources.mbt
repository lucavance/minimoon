///|
/// A UTF-8 build asset. Paths are relative to dist and must live below assets/.
pub(all) struct ResourceAsset {
  path : String
  content : String
} derive(Eq, Debug)

///|
/// Build-time resources, never included in the application runtime implicitly.
pub(all) struct ResourceBundle {
  id : String
  version : String
  wxss : String
  assets : Array[ResourceAsset]
} derive(Eq, Debug)

///|
/// Serialize a typed provider result for the native build probe.
pub fn encode(bundle : ResourceBundle) -> String {
  Json::object({
    "id": Json::string(bundle.id),
    "version": Json::string(bundle.version),
    "wxss": Json::string(bundle.wxss),
    "assets": Json::array(
      bundle.assets.map(asset => {
        Json::object({
          "path": Json::string(asset.path),
          "content": Json::string(asset.content),
        })
      }),
    ),
  }).stringify()
}
