#!/usr/bin/env bash
#
# xcframework_manifest.sh — print SHA-256 fingerprints that bind each
# committed xcframework to the tree it was built from.
#
# Usage: scripts/xcframework_manifest.sh inputs|outputs
#
#   inputs   one line per framework hashing every file it is built from:
#            its own `Sources/<Framework>`, plus `Sources/DashXCore`,
#            `build-project/project.yml`, and `scripts/build_xcframeworks.sh`.
#   outputs  one line per framework hashing every file in its xcframework.
#
# Paths are part of each hash, so adding, removing, or moving a file changes
# it. Files are those git would commit (tracked or untracked, not ignored),
# so a local build and a CI checkout of the same commit hash identically.
#
# `build_xcframeworks.sh` writes both sets to `xcframeworks/manifest.sha256`;
# `check_xcframeworks.sh` recomputes them and compares.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FRAMEWORKS=(DashX DashXNotificationServiceExtension)
SHARED_INPUTS=(Sources/DashXCore build-project/project.yml scripts/build_xcframeworks.sh)

fingerprint () {
  git ls-files -z --cached --others --exclude-standard -- "$@" \
    | LC_ALL=C sort -z -u \
    | while IFS= read -r -d '' path; do
        if [ -f "$path" ]; then
          shasum -a 256 "$path"
        fi
      done \
    | shasum -a 256 \
    | cut -d ' ' -f 1
}

case "${1:-}" in
  inputs)
    for framework in "${FRAMEWORKS[@]}"; do
      echo "$(fingerprint "Sources/$framework" "${SHARED_INPUTS[@]}")  inputs  $framework"
    done
    ;;
  outputs)
    for framework in "${FRAMEWORKS[@]}"; do
      echo "$(fingerprint "xcframeworks/$framework.xcframework")  outputs  $framework"
    done
    ;;
  *)
    echo "usage: $0 inputs|outputs" >&2
    exit 64
    ;;
esac
