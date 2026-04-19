#!/usr/bin/env bash
#
# build_xcframeworks.sh — Build the three distribution xcframeworks for the
# CocoaPods binary release path.
#
# Produces under xcframeworks/:
#   - DashXCore.xcframework                          shared models
#   - DashX.xcframework                              main SDK (Apollo baked in)
#   - DashXNotificationServiceExtension.xcframework  NSE base class
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

rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy `.swiftinterface` files from the Xcode intermediate build dir into the
# final framework's Modules/<name>.swiftmodule/ bundle. Xcode 26 ships them
# as build products but omits the install step into the archived framework.
install_swiftinterfaces () {
  local archive="$1"   # e.g. build/DashXCore-sim.xcarchive
  local scheme="$2"
  local triple_root="$3"   # e.g. iphonesimulator / iphoneos

  local modules_dir="$archive/Products/Library/Frameworks/$scheme.framework/Modules/$scheme.swiftmodule"
  local intermediates_base
  intermediates_base="$(find ~/Library/Developer/Xcode/DerivedData -type d \
    -path "*ArchiveIntermediates/$scheme/IntermediateBuildFilesPath/DashX.build/Release-$triple_root/$scheme.build/Objects-normal/*" \
    2>/dev/null | head -1)"

  [ -z "$intermediates_base" ] && return 0
  [ ! -d "$modules_dir" ] && return 0

  local arch
  arch="$(basename "$intermediates_base")"  # e.g. arm64
  local triple="$arch-apple-ios"
  [ "$triple_root" = "iphonesimulator" ] && triple="$arch-apple-ios-simulator"

  for iface in "$scheme.swiftinterface" "$scheme.private.swiftinterface"; do
    if [ -f "$intermediates_base/$iface" ]; then
      local dst_name="$triple.${iface#$scheme.}"
      cp "$intermediates_base/$iface" "$modules_dir/$dst_name"
    fi
  done

  # Simulator archives also contain a second arch (x86_64) — pick it up too.
  if [ "$triple_root" = "iphonesimulator" ]; then
    local x86_base
    x86_base="$(find ~/Library/Developer/Xcode/DerivedData -type d \
      -path "*ArchiveIntermediates/$scheme/IntermediateBuildFilesPath/DashX.build/Release-$triple_root/$scheme.build/Objects-normal/x86_64" \
      2>/dev/null | head -1)"
    if [ -n "$x86_base" ]; then
      for iface in "$scheme.swiftinterface" "$scheme.private.swiftinterface"; do
        if [ -f "$x86_base/$iface" ]; then
          local dst_name="x86_64-apple-ios-simulator.${iface#$scheme.}"
          cp "$x86_base/$iface" "$modules_dir/$dst_name"
        fi
      done
    fi
  fi
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
