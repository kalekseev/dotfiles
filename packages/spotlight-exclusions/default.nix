{ lib, writeShellApplication }:

writeShellApplication {
  name = "spotlight-exclusions";

  text = ''
    if [[ "''${1:-}" == "--help" || "''${1:-}" == "-h" ]]; then
      printf 'Usage: spotlight-exclusions PATH...\n'
      exit 0
    fi
    if [[ "$#" -eq 0 ]]; then
      printf 'Usage: spotlight-exclusions PATH...\n' >&2
      exit 2
    fi

    exec /usr/bin/osascript -l JavaScript ${./spotlight-exclusions.js} "$@"
  '';

  meta = {
    description = "Add paths to macOS Spotlight Search Privacy exclusions";
    mainProgram = "spotlight-exclusions";
    platforms = lib.platforms.darwin;
  };
}
