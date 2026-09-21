// Preserve the method API previously attached implicitly by trait implementations.

///|
pub extend EffectResolveResult with Debug::{to_repr}

///|
pub extend EffectResolveResult with Eq::{not_equal, equal}

///|
pub extend HostEffectOutcome with Debug::{to_repr}

///|
pub extend HostEffectOutcome with Eq::{not_equal, equal}
