///|
pub(all) struct Record {
  id : Int32
  draft : Draft
} derive(Eq, ToJson, @json.FromJson)

///|
pub(all) struct Store {
  version : Int32
  next_id : Int32
  records : Array[Record]
} derive(Eq, ToJson, @json.FromJson)

///|
pub extend Store with ToJson::{to_json}

///|
pub(all) struct Buffer {
  id : Int32?
  draft : Draft
  saved : Draft
  revision : Int32
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
  Open(Int32)
  Delete(Int32)
  ClearAll
  Initialize
} derive(Eq)

///|
pub(all) struct PendingWrite {
  token : Int32
  store : Store
  intent : Intent?
  buffer : Buffer
  saved_id : Int32?
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
  token : Int32
  revision : Int32
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
  epoch : Int32
  pending : PendingWrite?
  confirm : Intent?
  opening : Intent?
  notice : String
  echo : EchoModel
} derive(Eq)

///|
pub(all) enum WorkMsg {
  Reload
  Restored(Int32, Result[@minimoon.StorageResult, @minimoon.HostError])
  Title(String)
  Note(String)
  Choose(Intent)
  Confirm
  Cancel
  Save
  Written(Int32, Result[Unit, @minimoon.HostError])
  Send
  EchoFinished(Int32, Result[DraftEcho, Error])
}
