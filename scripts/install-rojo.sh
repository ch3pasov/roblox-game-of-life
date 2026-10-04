#!/usr/bin/env bash
set -euo pipefail

# Release asset and digest verified against rojo-rbx/rojo v7.7.1.
readonly ROJO_VERSION="7.7.1"
readonly ROJO_SHA256="00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4"
readonly ROJO_URL="https://github.com/rojo-rbx/rojo/releases/download/v${ROJO_VERSION}/rojo-${ROJO_VERSION}-linux-x86_64.zip"

: "${RUNNER_TEMP:?RUNNER_TEMP is required}"
: "${GITHUB_PATH:?GITHUB_PATH is required}"
install_dir="$(mktemp -d "$RUNNER_TEMP/rojo.XXXXXX")"
archive="$install_dir/rojo.zip"

curl --fail --location --retry 3 "$ROJO_URL" --output "$archive"
if ! printf '%s  %s\n' "$ROJO_SHA256" "$archive" | sha256sum --check --status; then
  echo "Rojo archive failed SHA-256 verification." >&2
  exit 1
fi
unzip -q "$archive" -d "$install_dir"

if [[ ! -f "$install_dir/rojo" ]]; then
  echo "Rojo binary was not found in the verified archive." >&2
  exit 1
fi
chmod +x "$install_dir/rojo"
printf '%s\n' "$install_dir" >> "$GITHUB_PATH"
