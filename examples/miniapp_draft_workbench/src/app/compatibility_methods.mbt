// Preserve the method API previously attached implicitly by trait implementations.

///|
pub extend Buffer with Eq::{not_equal, equal}

///|
pub extend Draft with @json.FromJson::{from_json}

///|
pub extend Draft with Eq::{not_equal, equal}

///|
pub extend Draft with ToJson::{to_json}

///|
pub extend DraftEcho with @json.FromJson::{from_json}

///|
pub extend EchoModel with Eq::{not_equal, equal}

///|
pub extend EchoStatus with Eq::{not_equal, equal}

///|
pub extend FetchModel with Eq::{not_equal, equal}

///|
pub extend Intent with Eq::{not_equal, equal}

///|
pub extend PendingWrite with Eq::{not_equal, equal}

///|
pub extend Record with @json.FromJson::{from_json}

///|
pub extend Record with Eq::{not_equal, equal}

///|
pub extend Record with ToJson::{to_json}

///|
pub extend StorageState with Eq::{not_equal, equal}

///|
pub extend Store with @json.FromJson::{from_json}

///|
pub extend Store with Eq::{not_equal, equal}

///|
pub extend Workbench with Eq::{not_equal, equal}
