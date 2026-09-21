// Preserve the method API previously attached implicitly by trait implementations.

///|
pub extend DirtyFlag with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DirtyFlag with Eq::{not_equal, equal}

///|
pub extend Node with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Node with Eq::{not_equal, equal}
