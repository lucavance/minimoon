///|
pub(all) enum Orientation {
  Horizontal
  Vertical
} derive(Eq, Debug)

///|
fn Orientation::semantic_name(self : Orientation) -> String {
  match self {
    Horizontal => "horizontal"
    Vertical => "vertical"
  }
}
