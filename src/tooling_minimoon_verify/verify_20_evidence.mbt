///|
fn string_array(json : Json, key : String) -> Array[String] {
  array(json, key).map(item => {
    match item {
      String(value) => value
      _ => abort(key + " must contain strings")
    }
  })
}

///|
fn current_evidence_scope() -> String {
  "current-v" + @versions.app_contract_version().to_string()
}

///|
async fn matching_evidence(app_root : String, fingerprint : String) -> Bool {
  let file = join(app_root, "generated/devtools.evidence.json")
  guard @fs.exists(file) else { false }
  let evidence = read_json(file)
  string(evidence, "scope") == current_evidence_scope() &&
  string(evidence, "status") == "passed" &&
  string(evidence, "artifactFingerprint") == fingerprint
}

///|
async fn evidence_check(
  app_root : String,
  fingerprint : String,
  required : Bool,
) -> Json {
  let file = join(app_root, "generated/devtools.evidence.json")
  let current = if required {
    matching_evidence(app_root, fingerprint)
  } else {
    false
  }
  status(
    "devtools-evidence",
    current || !required,
    if !required {
      "pending; required only by verify --release"
    } else if current {
      "passed evidence matches current artifact fingerprint"
    } else if !@fs.exists(file) {
      "current App Contract v" +
      @versions.app_contract_version().to_string() +
      " DevTools evidence is required for release"
    } else {
      "evidence is historical, failed, or belongs to a different artifact fingerprint"
    },
  )
}

///|
async fn sync_release_summary(
  app_root : String,
  fingerprint : String,
  current : Bool,
  automated_passed : Bool,
) -> Unit {
  let summary_file = join(app_root, "generated/release_summary.json")
  guard @fs.exists(summary_file) else { return }
  let summary = object(read_json(summary_file), "release_summary")
  let automated = match summary.get("automated") {
    Some(Object(fields)) => fields
    _ => Map([])
  }
  automated["status"] = Json::string(
    if automated_passed {
      "passed"
    } else {
      "failed"
    },
  )
  automated["artifactFingerprint"] = Json::string(fingerprint)
  summary["automated"] = Json::object(automated)
  summary["devtools"] = if current {
    Json::object({
      "status": Json::string("passed"),
      "evidence": Json::string("generated/devtools.evidence.json"),
      "artifactFingerprint": Json::string(fingerprint),
    })
  } else {
    Json::object({ "status": Json::string("pending"), "evidence": Json::null() })
  }
  write_json(summary_file, Json::object(summary))
}

///|
pub async fn verify(app_root : String, require_devtools : Bool) -> Json {
  let manifest_file = join(app_root, "generated/manifest.json")
  guard @fs.exists(manifest_file) else {
    abort("generated/manifest.json is missing; run minimoon build first")
  }
  let manifest = read_json(manifest_file)
  let checks = generated_checks(app_root, manifest)
  let app = read_json(join(app_root, "dist/app.json"))
  let clean_custom_navigation = valid_custom_navigation_app_config(app)
  checks.push(
    status(
      "custom-navigation-config",
      clean_custom_navigation,
      if clean_custom_navigation {
        "app.json omits system navigation fields that custom Skyline pages ignore"
      } else {
        "app.json.window must omit system navigation fields when every Skyline page uses navigationStyle=custom"
      },
    ),
  )
  let renderer_current = match field(manifest, "rendererProtocolVersion") {
    Number(value, ..) =>
      value == @versions.renderer_protocol_version().to_double()
    _ => false
  }
  let glass_easel = string(app, "renderer") == "skyline" &&
    string(app, "componentFramework") == "glass-easel"
  let definition_page = string(manifest, "hostRegistration") ==
    "page-definition-api"
  let renderer_version = @versions.renderer_protocol_version().to_string()
  checks.push(
    status(
      "renderer-v" + renderer_version + "-host",
      renderer_current && glass_easel && definition_page,
      if renderer_current && glass_easel && definition_page {
        "renderer protocol v" +
        renderer_version +
        " uses Skyline, glass-easel, and Page Definition API registration"
      } else {
        "renderer protocol v" +
        renderer_version +
        " requires Skyline/glass-easel and Page Definition API registration"
      },
    ),
  )
  let manifest_routes = array(manifest, "pages").map(page => {
    string(page, "route")
  })
  let app_routes = string_array(app, "pages")
  checks.push(
    status(
      "page-order",
      manifest_routes == app_routes,
      if manifest_routes == app_routes {
        "config order matches app.json and defines the home page"
      } else {
        "manifest pages=" +
        manifest_routes.join(",") +
        "; app pages=" +
        app_routes.join(",")
      },
    ),
  )
  let fingerprint = artifact_fingerprint(app_root)
  let current_evidence = if require_devtools {
    matching_evidence(app_root, fingerprint)
  } else {
    false
  }
  let automated_passed = checks.all(check => string(check, "status") == "passed")
  checks.push(evidence_check(app_root, fingerprint, require_devtools))
  let passed = checks.all(check => string(check, "status") == "passed")
  sync_release_summary(
    app_root, fingerprint, current_evidence, automated_passed,
  )
  let report = Json::object({
    "schemaVersion": Json::number(1.0, repr="1"),
    "status": Json::string(if passed { "passed" } else { "failed" }),
    "release": Json::boolean(require_devtools),
    "artifactFingerprint": Json::string(fingerprint),
    "checks": Json::array(checks),
  })
  write_json(join(app_root, "generated/verify_report.json"), report)
  report
}

///|
pub async fn record_devtools(
  app_root : String,
  status_value : String,
  recorded_at : String,
  tool_version : String,
  notes : String,
) -> Json {
  guard status_value == "passed" || status_value == "failed" else {
    raise Failure::Failure("DevTools status must be passed or failed")
  }
  guard recorded_at != "" else {
    raise Failure::Failure(
      "--recorded-at is required, for example 2026-09-04T13:50:00+08:00",
    )
  }
  guard tool_version != "" else {
    raise Failure::Failure("--tool-version is required")
  }
  let config = read_json(join(app_root, "miniapp.minimoon.json"))
  let summary_file = join(app_root, "generated/release_summary.json")
  guard @fs.exists(summary_file) &&
    string(read_json(summary_file), "mode") == "release" else {
    raise Failure::Failure(
      "DevTools evidence must describe release artifacts; run `minimoon build . --mode release` first",
    )
  }
  let evidence = Json::object({
    "schemaVersion": Json::number(1.0, repr="1"),
    "scope": Json::string(current_evidence_scope()),
    "status": Json::string(status_value),
    "app": field(config, "name"),
    "recordedAt": Json::string(recorded_at),
    "tool": Json::string("WeChat Developer Tools"),
    "toolVersion": Json::string(tool_version),
    "artifactFingerprint": Json::string(artifact_fingerprint(app_root)),
    "notes": Json::string(notes),
  })
  write_json(join(app_root, "generated/devtools.evidence.json"), evidence)
  let summary = object(read_json(summary_file), "release_summary")
  summary["devtools"] = Json::object({
    "status": Json::string(status_value),
    "evidence": Json::string("generated/devtools.evidence.json"),
    "artifactFingerprint": field(evidence, "artifactFingerprint"),
  })
  write_json(summary_file, Json::object(summary))
  evidence
}
