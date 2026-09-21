// Preserve the method API previously attached implicitly by trait implementations.

///|
pub extend ColorMode with Debug::{to_repr}

///|
pub extend ColorMode with Eq::{not_equal, equal}

///|
pub extend TextDirection with Debug::{to_repr}

///|
pub extend TextDirection with Eq::{not_equal, equal}

///|
pub extend Theme with Debug::{to_repr}

///|
pub extend Theme with Eq::{not_equal, equal}

///|
pub extend Tokens with Debug::{to_repr}

///|
pub extend Tokens with Eq::{not_equal, equal}
