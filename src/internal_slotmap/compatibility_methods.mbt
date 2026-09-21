// Preserve the method API previously attached implicitly by trait implementations.

///|
pub extend Id with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Id with Eq::{not_equal, equal}

///|
pub extend Id with Hash::{hash, hash_combine}
