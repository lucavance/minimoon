///|
test "vp policy rejects direct process and repository helper launches" {
  for
    source in [
      "@process.collect_output(\n  \"bun\", [\"--version\"],\n)", "@process.run(\"bunx\", [\"mmdc\"])",
      "@toolchain.run(\"bun\", args)", "@toolchain.collect_output(\"bun\", args)",
      "run(\"bun\", args, root)", "run_checked(\"bun\", args, root, label)", "run(root, label(\"nested\", 1), \"bun\", args)",
      "require_command_failure(\"failure\", \"bun\", args, root, needle)", "supervised_check_process(root, base, \"bun\", args)",
    ] {
    assert_eq(bare_bun_process_violations(source).length(), 1, msg=source)
  }
}

///|
test "vp policy allows backend arguments metadata and source fixtures" {
  for
    source in [
      "@process.run(\"vp\", [\"env\", \"exec\", \"bun\", \"--version\"])", "@process.run(\"vp\", @toolchain.bun_args(args))",
      "let manager = { \"name\": \"bun\", \"version\": \"1.4.2\" }", "// @process.run(\"bun\", [])\nlet literal = \"@process.run(\\\"bun\\\", [])\"",
      "#|toolchain: { bun: Bun.version }",
    ] {
    assert_true(bare_bun_process_violations(source).is_empty(), msg=source)
  }
}
