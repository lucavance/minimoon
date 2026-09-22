///|
priv struct ArtifactLayout {
  app_root : String
  config_file : String
  dist : String
}

///|
async fn artifact_layout(
  app_root : String,
  dist_dir? : String,
  config_path? : String,
) -> ArtifactLayout {
  let config_file = config_path.unwrap_or(
    join(app_root, "miniapp.minimoon.json"),
  )
  let config = if config_path is Some(_) || @fs.exists(config_file) {
    Some(read_json(config_file))
  } else {
    None
  }
  let dist = match dist_dir {
    Some(directory) =>
      if Path::is_absolute(directory) {
        Path::normalize(directory).to_string()
      } else {
        join(app_root, directory)
      }
    None => {
      let directory = config
        .map(value => string(value, "distDir", fallback="dist"))
        .unwrap_or("dist")
      guard directory != "" &&
        !Path::is_absolute(directory) &&
        !directory.contains("..") else {
        raise Failure::Failure(
          "distDir must be a nonempty app-relative directory",
        )
      }
      join(app_root, directory)
    }
  }
  let relative = portable_relative_path(app_root, dist)
  guard relative != "" &&
    relative != "." &&
    relative != ".." &&
    !relative.has_prefix("../") &&
    !Path::is_absolute(relative) else {
    raise Failure::Failure(
      "distDir must remain below the application directory",
    )
  }
  { app_root, config_file, dist, }
}
