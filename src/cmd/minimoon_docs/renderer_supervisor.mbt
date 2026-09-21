///|
fn renderer_supervisor_source() -> String {
  (
    #|const { spawn, spawnSync } = require('node:child_process');
    #|const { constants } = require('node:os');
    #|const [command, ...args] = JSON.parse(process.argv[2]);
    #|const windows = process.platform === 'win32';
    #|let child;
    #|let finishing = false;
    #|
    #|function signalTree(signal) {
    #|  if (!child?.pid) return;
    #|  if (windows) {
    #|    spawnSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], {
    #|      stdio: 'ignore', windowsHide: true,
    #|    });
    #|    return;
    #|  }
    #|  try { process.kill(-child.pid, signal); }
    #|  catch (error) { if (error.code !== 'ESRCH') throw error; }
    #|}
    #|
    #|function treeExists() {
    #|  if (!child?.pid || windows) return false;
    #|  try { process.kill(-child.pid, 0); return true; }
    #|  catch (error) { if (error.code === 'ESRCH') return false; throw error; }
    #|}
    #|
    #|function finish(code) {
    #|  if (finishing) return;
    #|  finishing = true;
    #|  // Keep the process-group ID even when the package runner has exited.
    #|  // Its browser or renderer descendants may still own output pipes.
    #|  signalTree('SIGTERM');
    #|  if (!treeExists()) return process.exit(code);
    #|  const poll = setInterval(() => {
    #|    if (!treeExists()) process.exit(code);
    #|  }, 10);
    #|  setTimeout(() => {
    #|    clearInterval(poll);
    #|    signalTree('SIGKILL');
    #|    // Reaping the direct child is independent of stopping descendants.
    #|    setTimeout(() => process.exit(code), 10);
    #|  }, 250);
    #|}
    #|
    #|process.on('SIGTERM', () => finish(143));
    #|process.on('SIGINT', () => finish(130));
    #|child = spawn(command, args, {
    #|  detached: !windows, stdio: 'inherit', windowsHide: true,
    #|});
    #|child.once('error', error => {
    #|  console.error(`Unable to start Mermaid renderer: ${error.message}`);
    #|  finish(1);
    #|});
    #|child.once('exit', (code, signal) => {
    #|  finish(code ?? (128 + (constants.signals[signal] ?? 1)));
    #|});
  )
}

///|
async fn collect_renderer_output(
  command : String,
  args : Array[String],
  root : String,
) -> (Int, &@io.Data, &@io.Data) {
  let temp = @fs.tmpdir(prefix="minimoon-mermaid-supervisor")
  defer cleanup_diagram_temporary(temp)
  let supervisor = join(temp, "renderer-supervisor.cjs")
  write(supervisor, renderer_supervisor_source())
  @toolchain.collect_output(
    "vp",
    @toolchain.bun_args([
      supervisor,
      Json::array([command, ..args].map(Json::string)).stringify(),
    ]),
    cwd=root,
  )
}
