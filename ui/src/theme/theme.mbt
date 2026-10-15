///|
/// Skyline-safe adaptation of RUI tokens (MIT). See THIRD_PARTY_NOTICES.md.
pub(all) enum ColorMode {
  Light
  Dark
} derive(Eq, Debug)

///|
pub(all) enum TextDirection {
  Ltr
  Rtl
} derive(Eq, Debug)

///|
/// Nova is the current compact recipe; VegaV1 preserves the original recipe.
pub(all) enum Preset {
  Nova
  VegaV1
} derive(Eq, Debug)

///|
pub extend Preset with Eq::{equal, not_equal}

///|
pub extend Preset with @debug.Debug::{to_repr}

///|
pub(all) struct Tokens {
  background : String
  foreground : String
  primary : String
  primary_foreground : String
  muted : String
  muted_foreground : String
  border : String
  destructive : String
  radius : Int32
} derive(Eq, Debug)

///|
pub fn tokens(mode~ : ColorMode = Light, preset~ : Preset = Nova) -> Tokens {
  let palette = match mode {
    Light =>
      {
        background: "#ffffff",
        foreground: "#171717",
        primary: "#262626",
        primary_foreground: "#fafafa",
        muted: "#f5f5f5",
        muted_foreground: "#737373",
        border: "#e5e5e5",
        destructive: "#dc2626",
        radius: 10,
      }
    Dark =>
      {
        background: "#171717",
        foreground: "#fafafa",
        primary: "#e5e5e5",
        primary_foreground: "#262626",
        muted: "#262626",
        muted_foreground: "#a3a3a3",
        border: "#404040",
        destructive: "#f87171",
        radius: 10,
      }
  }
  match preset {
    VegaV1 => palette
    Nova =>
      match mode {
        Light =>
          {
            ..palette,
            foreground: "#0a0a0a",
            primary: "#171717",
            destructive: "#e7000b",
          }
        Dark =>
          {
            ..palette,
            background: "#0a0a0a",
            primary_foreground: "#171717",
            border: "#ffffff1a",
            destructive: "#ff6467",
          }
      }
  }
}

///|
pub struct Theme {
  preset : Preset
  mode : ColorMode
  direction : TextDirection
  tokens : Tokens
} derive(Eq, Debug)

///|
pub fn theme(
  mode~ : ColorMode = Light,
  direction~ : TextDirection = Ltr,
  tokens? : Tokens,
  preset~ : Preset = Nova,
) -> Theme {
  let palette = tokens.unwrap_or(default_tokens(mode, preset))
  guard palette.radius >= 0 else { abort("theme radius must be nonnegative") }
  for
    color in [
      palette.background,
      palette.foreground,
      palette.primary,
      palette.primary_foreground,
      palette.muted,
      palette.muted_foreground,
      palette.border,
      palette.destructive,
    ] {
    guard color.has_prefix("#") && [4, 5, 7, 9].contains(color.length()) else {
      abort("theme colors must be native hexadecimal literals")
    }
    let mut first = true
    for character in color.iter() {
      if first {
        first = false
        continue
      }
      guard (character >= '0' && character <= '9') ||
        (character >= 'a' && character <= 'f') ||
        (character >= 'A' && character <= 'F') else {
        abort("theme colors must be native hexadecimal literals")
      }
    }
  }
  { mode, direction, tokens: palette, preset, }
}

///|
fn default_tokens(mode : ColorMode, preset : Preset) -> Tokens {
  tokens(mode~, preset~)
}

///|
pub fn Theme::class_name(self : Theme) -> String {
  "mmui-theme " +
  (match self.preset {
    Nova => "mmui-nova"
    VegaV1 => "mmui-vega-v1"
  }) +
  " mmui-" +
  (match self.mode {
    Light => "light"
    Dark => "dark"
  }) +
  " mmui-" +
  (match self.direction {
    Ltr => "ltr"
    Rtl => "rtl"
  })
}

///|
pub fn Theme::style(self : Theme) -> String {
  let t = self.tokens
  "--mmui-background:" +
  t.background +
  ";--mmui-foreground:" +
  t.foreground +
  ";--mmui-primary:" +
  t.primary +
  ";--mmui-primary-foreground:" +
  t.primary_foreground +
  ";--mmui-muted:" +
  t.muted +
  ";--mmui-muted-foreground:" +
  t.muted_foreground +
  ";--mmui-border:" +
  t.border +
  ";--mmui-destructive:" +
  t.destructive +
  ";--mmui-radius:" +
  t.radius.to_string() +
  "px;"
}
