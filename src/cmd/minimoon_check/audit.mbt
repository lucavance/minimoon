///|
struct DependencyAuditDecision {
  status : String
  reason : String
}

///|
fn dependency_audit_record_identity(record : String) -> (String, String)? {
  let parts = record.split("@").map(part => part.to_owned()).collect()
  guard parts.length() >= 2 else { return None }
  let version = parts[parts.length() - 1]
  let name = parts[:parts.length() - 1].to_owned().join("@")
  guard name != "" && version != "" else { return None }
  Some((name, version))
}

///|
fn dependency_audit_lock_packages(source : String) -> Map[String, Bool] raise {
  let lock = @json5.parse(source)
  guard lock is Object(fields) &&
    fields.get("lockfileVersion") == Some(Json::number(1)) &&
    fields.get("configVersion") == Some(Json::number(1)) &&
    fields.get("packages") is Some(Object(packages)) &&
    !packages.is_empty() else {
    raise Failure("unsupported or empty bun.lock")
  }
  let names : Map[String, Bool] = Map([])
  for path, value in packages {
    guard value is Array([String(record), String(_), Object(_), String(_), ..]) &&
      dependency_audit_record_identity(record) is Some((name, _)) else {
      raise Failure("invalid bun.lock package: " + path)
    }
    names[name] = true
  }
  names
}

///|
fn evaluate_dependency_audit(
  exit_code : Int32,
  stdout : String,
  stderr : String,
  lock_source : String,
) -> DependencyAuditDecision {
  fn inspect() -> DependencyAuditDecision raise {
    guard (exit_code == 0 || exit_code == 1) && stderr == "" else {
      raise Failure("audit command failed (exit \{exit_code}); see stderr.log")
    }
    let names = dependency_audit_lock_packages(lock_source)
    let report = @json.parse(stdout)
    guard report is Object(packages) else {
      raise Failure("Bun audit JSON must be an object")
    }
    for name, value in packages {
      guard names.contains(name) &&
        value is Array(entries) &&
        !entries.is_empty() else {
        raise Failure("invalid advisory list: " + name)
      }
      for entry in entries {
        guard entry is Object(fields) &&
          fields.get("url") is Some(String(url)) &&
          url.has_prefix("https://github.com/advisories/GHSA-") &&
          fields.get("severity") is Some(String(severity)) else {
          raise Failure("invalid advisory record: " + name)
        }
        match severity {
          "info" | "low" | "moderate" => ()
          "high" | "critical" =>
            raise Failure(
              "blocking " + severity + " advisory: " + name + " " + url,
            )
          _ =>
            raise Failure(
              "blocking or unknown severity: " + name + " " + severity,
            )
        }
      }
    }
    guard exit_code == 0 else {
      raise Failure("audit exit code disagrees with high/critical findings")
    }
    { status: "clean", reason: "No high or critical advisory reported", }
  }
  inspect() catch {
    err => { status: "failed", reason: "\{err}", }
  }
}

///|
fn dependency_audit_summary(
  decision : DependencyAuditDecision,
  exit_code : Int32?,
) -> Json {
  Json::object({
    "status": Json::string(decision.status),
    "reason": Json::string(decision.reason),
    "exitCode": match exit_code {
      Some(code) => Json::number(code.to_double())
      None => Json::null()
    },
  })
}

///|
async fn persist_dependency_audit(
  directory : String,
  stdout : String,
  stderr : String,
  decision : DependencyAuditDecision,
  exit_code : Int32?,
) -> Unit nocancel {
  @async.protect_from_cancel(() => {
    let summary = dependency_audit_summary(decision, exit_code).stringify(
        indent=2,
      ) +
      "\n"
    for
      (name, source) in [
        ("audit.json", stdout),
        ("stderr.log", stderr),
        ("summary.json", summary),
      ] {
      @fs.write_file(
        join(directory, name),
        source,
        create_mode=CreateOrTruncate,
      )
    }
  })
}

///|
async fn audit_suite(root : String) -> Unit {
  let directory = join(root, "_build/dependency-audit")
  @fs.mkdir(directory, recursive=true, allow_exist=true, permission=0o700)
  let mut stdout = ""
  let mut stderr = ""
  let mut exit_code : Int32? = None
  persist_dependency_audit(
    directory,
    stdout,
    stderr,
    { status: "failed", reason: "audit not completed", },
    exit_code,
  )
  let decision = try {
    let (code, output, error) = @async.with_timeout(120000, () => {
      @toolchain.collect_output(
        "vp",
        @toolchain.bun_args(["audit", "--audit-level=high", "--json"]),
        cwd=root,
      )
    })
    exit_code = Some(code)
    stdout = output.text()
    stderr = error.text()
    let lock = @fs.read_file(join(root, "bun.lock")).text()
    evaluate_dependency_audit(code, stdout, stderr, lock)
  } catch {
    err =>
      { status: "failed", reason: "audit command or bun.lock failed: \{err}", }
  }
  persist_dependency_audit(directory, stdout, stderr, decision, exit_code)
  println("Dependency audit: " + decision.status + "; " + decision.reason)
  guard decision.status != "failed" else {
    abort("Dependency audit failed: " + decision.reason)
  }
}
