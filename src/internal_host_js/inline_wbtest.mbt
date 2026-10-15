///|
#cfg(target="js")
extern "js" fn test_inline_protocol(source : String) -> String =
  #|source => {
  #|  try {
  #|    const module = {exports:{}}; new Function("module", source)(module)
  #|    const {applyPatch, decodeCompactNode, validateNode} = module.exports
  #|    const node = (kind, id, children=[]) => ({kind, identity:id, text:"", props:{}, events:{}, children})
  #|    const tree = node("inline", "root", [node("text","a"),node("image","b")])
  #|    const original = JSON.stringify(tree)
  #|    const patch = ops => applyPatch({type:"PatchViewTree",component_id:"test",base_revision:0,revision:1,ops},"test",0,tree)
  #|    const assert = (ok, message) => { if (!ok) throw Error(message) }
  #|    for (const invalid of [null, [], {}, {...tree, extra:0}, {...tree, props:null}, {...tree, props:[]}, {...tree, events:null}, {...tree, events:[]}, {...tree, children:null}, {...tree, children:[null]}]) {
  #|      assert(!validateNode(invalid), "node shape validation accepted malformed data")
  #|    }
  #|    const splice = items => ({op:"splice",path:["children"],index:0,delete_count:0,items})
  #|    assert(patch([splice([node("text","new")])]), "valid inline insertion rejected")
  #|    assert(patch([{op:"set",path:["children",0,"text"],value:"changed"}]), "inline leaf update rejected")
  #|    assert(!patch([splice([node("view","bad")])]), "inline accepted a block")
  #|    assert(!patch([{op:"move",path:["children"],from:0,to:1,identity:"a",item:node("view","a")}]), "inline move accepted a block replacement")
  #|    assert(!patch([{...splice([node("text","nested")]),path:["children",0,"children"]}]), "inline text accepted children")
  #|    assert(JSON.stringify(tree) === original, "rejected inline patches mutated authoritative state")
  #|    const compact = n => [n.kind,n.identity,n.text,n.props,n.events,n.children.map(compact)]
  #|    decodeCompactNode(compact(tree))
  #|    let rejected = false
  #|    try { decodeCompactNode(compact(node("inline","bad",[node("view","block")])) ) } catch { rejected = true }
  #|    assert(rejected, "compact decoder accepted an invalid inline tree")
  #|    return ""
  #|  } catch (error) { return String(error.stack || error) }
  #|}

///|
#cfg(target="js")
test "inline host protocol rejects invalid children atomically" {
  assert_eq(test_inline_protocol(shared_protocol_bridge()), "")
}
