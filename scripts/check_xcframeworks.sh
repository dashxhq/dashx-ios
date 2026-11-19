#!/usr/bin/env bash
#
# check_xcframeworks.sh — fail when the committed xcframeworks are stale.
#
# Usage: scripts/check_xcframeworks.sh
#
# 1. Recomputes the fingerprints from `xcframework_manifest.sh` and compares
#    them with `xcframeworks/manifest.sha256`, written by the last
#    `build_xcframeworks.sh` run. An inputs mismatch means the tree changed
#    after that build; an outputs mismatch means the xcframework was edited
#    or only partly committed.
# 2. Requires the podspec version and PACKAGE_VERSION to equal
#    MARKETING_VERSION, which the inputs fingerprint already ties to the
#    built frameworks.
#
# CI runs this on PRs into main. Run it locally before opening a release PR.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

MANIFEST=xcframeworks/manifest.sha256
REBUILD_HINT="Run scripts/build_xcframeworks.sh and commit xcframeworks/."

errors=0
fail () {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::error::$1"
  else
    echo "error: $1" >&2
  fi
  errors=$((errors + 1))
}

if [ ! -f "$MANIFEST" ]; then
  fail "$MANIFEST is missing. $REBUILD_HINT"
else
  inputs="$(./scripts/xcframework_manifest.sh inputs)"
  outputs="$(./scripts/xcframework_manifest.sh outputs)"
  while read -r digest kind framework; do
    recorded="$(awk -v kind="$kind" -v framework="$framework" \
      '$2 == kind && $3 == framework { print $1 }' "$MANIFEST")"
    [ "$recorded" = "$digest" ] && continue
    case "$kind" in
      inputs)
        fail "$framework.xcframework was not built from this tree: Sources/$framework, Sources/DashXCore, project.yml, or build_xcframeworks.sh changed since the last build. $REBUILD_HINT"
        ;;
      outputs)
        fail "$framework.xcframework does not match the build recorded in $MANIFEST; it was edited or only partly committed. $REBUILD_HINT"
        ;;
    esac
  done <<<"$inputs"$'\n'"$outputs"
fi

read_version () {
  sed -n "s/$2/\1/p" "$1" | head -n 1
}

marketing="$(read_version build-project/project.yml '^ *MARKETING_VERSION: *"\(.*\)"$')"
podspec="$(read_version DashX.podspec '^ *s\.version *= *"\(.*\)"$')"
package="$(read_version Sources/DashX/Constants.swift '^ *static let PACKAGE_VERSION = "\(.*\)"$')"

if [ -z "$marketing" ] || [ -z "$podspec" ] || [ -z "$package" ]; then
  fail "Could not read MARKETING_VERSION ('$marketing'), the podspec version ('$podspec'), or PACKAGE_VERSION ('$package')."
else
  [ "$podspec" = "$marketing" ] || fail "DashX.podspec version $podspec does not match MARKETING_VERSION $marketing."
  [ "$package" = "$marketing" ] || fail "PACKAGE_VERSION $package does not match MARKETING_VERSION $marketing."
fi

if [ "$errors" -gt 0 ]; then
  exit 1
fi
echo "xcframeworks match this tree (version $marketing)."
