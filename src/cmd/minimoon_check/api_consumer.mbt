///|
let frozen_api_consumer_series = "0.1"

///|
let frozen_api_consumer_files : Array[String] = [
  "moon.mod", "src/moon.pkg", "src/consumer.mbt",
]

///|
async fn copy_frozen_api_consumer(root : String, destination : String) -> Unit {
  let fixture = join(
    root,
    "src/cmd/minimoon_check/fixtures/api/consumers/" +
    frozen_api_consumer_series,
  )
  @fs.mkdir(destination, permission=0o755, recursive=true)
  @fs.mkdir(join(destination, "src"), permission=0o755, recursive=true)
  for path in frozen_api_consumer_files {
    require_file(fixture, path)
    @fs.write_file(
      join(destination, path),
      @fs.read_file(join(fixture, path)).text(),
      create_mode=CreateOrTruncate,
      permission=0o644,
    )
  }
}

///|
async fn frozen_api_consumer_gate(root : String) -> Unit {
  let product_version = @versions.product_version()
  guard api_baseline_series(product_version) is Some(_) else {
    abort(
      "no frozen public API consumer exists for product version " +
      product_version,
    )
  }
  println("\n==> Frozen " + frozen_api_consumer_series + " registry consumer")
  run(root, "Package public API candidate", "moon", ["package", "--frozen"])
  let archive = join(
    root,
    "_build/publish/lampclaw-minimoon-" + product_version + ".zip",
  )
  require_file(
    root,
    "_build/publish/lampclaw-minimoon-" + product_version + ".zip",
  )
  let temp = @fs.tmpdir(prefix="minimoon-api-consumer")
  let package_root = join(temp, "package")
  let consumer = join(temp, "consumer")
  @fs.mkdir(package_root, permission=0o755, recursive=true)
  run(root, "Unpack public API candidate", "unzip", [
    "-q", archive, "-d", package_root,
  ])
  copy_frozen_api_consumer(root, consumer)
  run(
    root,
    "Bind frozen consumer to unpacked registry candidate",
    "moon",
    ["work", "init", "package", "consumer"],
    cwd=temp,
  )
  for target in ["js", "native"] {
    run(
      root,
      "Check frozen consumer (" + target + ")",
      "moon",
      ["check", "--target", target, "--deny-warn"],
      cwd=temp,
    )
    run(
      root,
      "Build frozen consumer (" + target + ")",
      "moon",
      ["build", "--target", target, "--deny-warn"],
      cwd=temp,
    )
  }
}
