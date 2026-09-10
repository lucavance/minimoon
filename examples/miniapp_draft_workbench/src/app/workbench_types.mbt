///|
pub(all) struct Record {
  id : Int
  draft : Draft
} derive(Eq, ToJson, @json.FromJson)

///|
pub(all) struct Store {
  version : Int
  next_id : Int
  records : Array[Record]
} derive(Eq, ToJson, @json.FromJson)

///|
extend Store with ToJson::{to_json}

///|
pub(all) struct Buffer {
  id : Int?
  draft : Draft
  saved : Draft
  revision : Int
} derive(Eq)

///|
pub(all) enum StorageState {
  Loading
  Ready
  Writing
  ReadFailed
} derive(Eq)

///|
pub(all) enum Intent {
  New
  Open(Int)
  Delete(Int)
  ClearAll
  Initialize
} derive(Eq)

///|
pub(all) struct PendingWrite {
  token : Int
  store : Store
  intent : Intent?
  buffer : Buffer
  saved_id : Int?
} derive(Eq)

///|
pub(all) enum EchoStatus {
  EchoIdle
  EchoLoading
  EchoOk(Draft)
  EchoFailed(String)
  EchoOutdated
} derive(Eq)

///|
pub(all) struct EchoModel {
  token : Int
  revision : Int
  submitted : Draft
  status : EchoStatus
} derive(Eq)

///|
pub(all) struct DraftEcho {
  json : Draft
} derive(@json.FromJson)

///|
pub(all) struct Workbench {
  store : Store
  buffer : Buffer
  storage : StorageState
  epoch : Int
  pending : PendingWrite?
  confirm : Intent?
  opening : Intent?
  notice : String
  echo : EchoModel
} derive(Eq)

///|
pub(all) enum WorkMsg {
  Reload
  Restored(Int, Result[@minimoon.StorageResult, @minimoon.HostError])
  Title(String)
  Note(String)
  Choose(Intent)
  Confirm
  Cancel
  Save
  Written(Int, Result[Unit, @minimoon.HostError])
  Send
  EchoFinished(Int, Result[DraftEcho, Error])
}
