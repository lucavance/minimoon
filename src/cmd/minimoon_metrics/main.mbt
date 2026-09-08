///|
async fn main {
  let args = @env.args()
  let mut include_untracked = false
  let mut json = false
  for index = 1; index < args.length(); index = index + 1 {
    match args[index] {
      "--json" => json = true
      "--include-untracked" => include_untracked = true
      _ => abort("unknown minimoon metrics option: " + args[index])
    }
  }
  let root = metrics_repository_root(@env.current_dir().unwrap())
  let ledger = measure_files(root, include_untracked)
  let embedded = embedded_metrics(ledger.sources)
  let report = metrics_report(ledger, embedded, include_untracked)
  if json {
    println(report.stringify(indent=2))
  } else {
    print_metrics_report(ledger, embedded, include_untracked)
  }
}
