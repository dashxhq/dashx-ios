#!/usr/bin/env bash
#
# build_xcframeworks.sh — Build the distribution xcframeworks for the
# CocoaPods binary release path.
#
# Produces under xcframeworks/:
#   - DashX.xcframework                              main SDK (Apollo + DashXCore baked in)
#   - DashXNotificationServiceExtension.xcframework  NSE base class (DashXCore baked in)
#
# `DashXCore` sources are compiled into each framework directly (see
# `project.yml` → "Each framework target includes a copy of DashXCore"),
# so no separate Core xcframework is emitted on the CocoaPods path. SPM
# consumers still see DashXCore as its own library via `Package.swift`.
#
# Each xcframework carries two slices: ios-arm64 (device) + ios-arm64_x86_64-simulator.
# The build is driven by `DashX.xcodeproj` (regenerate from `project.yml` via
# `xcodegen generate` whenever sources or settings change).
#
# `BUILD_LIBRARIES_FOR_DISTRIBUTION=YES` produces a `.swiftinterface`, required
# for `xcodebuild -create-xcframework`. On Xcode 26+ the install step silently
# skips copying `.swiftinterface` into the framework bundle even when the flag
# is set — we copy them over manually from the intermediate build dir as a
# workaround.
#
# Run locally from the repo root, then commit `xcframeworks/` before tagging.
# See CONTRIBUTING.md → "Cutting a release" for the full release flow.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

BUILD_DIR="$REPO_ROOT/build"
OUTPUT_DIR="$REPO_ROOT/xcframeworks"
SCHEMES=(DashX DashXNotificationServiceExtension)

# Wipe the committed `xcframeworks/` before re-emitting. If xcodebuild fails
# partway, the repo is left without binaries until the script completes —
# recover with `git checkout -- xcframeworks/` and re-run.
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy `.swiftinterface` files from the Xcode intermediate build dir into the
# final framework's Modules/<name>.swiftmodule/ bundle. Xcode 26 ships them
# as build products but omits the install step into the archived framework.
#
# A simulator archive on Apple Silicon contains both `arm64/` and `x86_64/`
# subdirs under `Objects-normal/`, and `-create-xcframework` silently drops
# any arch whose `.swiftinterface` is missing. Walk every arch dir rather
# than picking one — filesystem ordering is not load-bearing.
install_swiftinterfaces () {
  local archive="$1"       # e.g. build/DashX-sim.xcarchive
  local scheme="$2"
  local triple_root="$3"   # iphonesimulator / iphoneos

  local modules_dir="$archive/Products/Library/Frameworks/$scheme.framework/Modules/$scheme.swiftmodule"
  [ ! -d "$modules_dir" ] && return 0

  local arch_roots
  arch_roots="$(find ~/Library/Developer/Xcode/DerivedData -type d \
    -path "*ArchiveIntermediates/$scheme/IntermediateBuildFilesPath/DashX.build/Release-$triple_root/$scheme.build/Objects-normal/*" \
    2>/dev/null)"

  [ -z "$arch_roots" ] && return 0

  while IFS= read -r arch_base; do
    [ -z "$arch_base" ] && continue
    local arch
    arch="$(basename "$arch_base")"  # arm64 / x86_64
    local triple="$arch-apple-ios"
    [ "$triple_root" = "iphonesimulator" ] && triple="$arch-apple-ios-simulator"

    for iface in "$scheme.swiftinterface" "$scheme.private.swiftinterface"; do
      if [ -f "$arch_base/$iface" ]; then
        local dst_name="$triple.${iface#$scheme.}"
        cp "$arch_base/$iface" "$modules_dir/$dst_name"
      fi
    done
  done <<< "$arch_roots"
}

for scheme in "${SCHEMES[@]}"; do
  echo ""
  echo "=== Building $scheme ==="

  for platform in "iOS Simulator" "iOS"; do
    sdk="iphonesimulator"
    slice="sim"
    if [ "$platform" = "iOS" ]; then
      sdk="iphoneos"
      slice="ios"
    fi

    xcodebuild archive \
      -project DashX.xcodeproj \
      -scheme "$scheme" \
      -destination "generic/platform=$platform" \
      -archivePath "$BUILD_DIR/$scheme-$slice.xcarchive" \
      -sdk "$sdk" \
      SKIP_INSTALL=NO \
      BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

    install_swiftinterfaces "$BUILD_DIR/$scheme-$slice.xcarchive" "$scheme" "$sdk"
  done

  xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/$scheme-sim.xcarchive/Products/Library/Frameworks/$scheme.framework" \
    -framework "$BUILD_DIR/$scheme-ios.xcarchive/Products/Library/Frameworks/$scheme.framework" \
    -output "$OUTPUT_DIR/$scheme.xcframework"
done

rm -rf "$BUILD_DIR"

echo ""
echo "✓ xcframeworks built at $OUTPUT_DIR/"
du -sh "$OUTPUT_DIR"/*.xcframework
