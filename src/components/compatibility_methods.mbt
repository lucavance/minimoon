// Preserve the method API previously attached implicitly by trait implementations.

///|
pub extend MenuPlacement with Debug::{to_repr}

///|
pub extend MenuPlacement with Eq::{not_equal, equal}

///|
pub extend MenuState with Eq::{not_equal, equal}

///|
pub extend Orientation with Debug::{to_repr}

///|
pub extend Orientation with Eq::{not_equal, equal}

///|
pub extend SheetSide with Debug::{to_repr}

///|
pub extend SheetSide with Eq::{not_equal, equal}
