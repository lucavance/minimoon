///|
#derive(Eq, Debug)
pub(all) enum Orientation {
  Horizontal
  Vertical
}

///|
fn Orientation::semantic_name(self : Orientation) -> String {
  match self {
    Horizontal => "horizontal"
    Vertical => "vertical"
  }
}
