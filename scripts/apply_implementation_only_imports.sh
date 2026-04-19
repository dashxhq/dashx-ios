#!/usr/bin/env bash
#
# apply_implementation_only_imports.sh — rewrite every Apollo import in the
# codegen output to `@_implementationOnly import` so Apollo names don't leak
# into DashX's public `.swiftinterface`.
#
# Why: DashX ships via the CocoaPods binary path as an xcframework with
# Apollo statically baked in. Consumers of the xcframework do NOT have
# Apollo as a module at build time — if DashX's interface references
# `Apollo.*` or `ApolloAPI.*`, their build fails with "no such module
# 'Apollo'". Making the generated DashXGql types `internal` (via
# apollo-codegen-config.json) hides them from the public API, but the
# file-level `import Apollo` / `@_exported import ApolloAPI` statements
# themselves still leak into the interface unless flagged
# `@_implementationOnly` or `internal import`.
#
# Run AFTER `apollo-ios-cli generate`. Idempotent — skips files already
# rewritten.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRAPHQL_DIR="$REPO_ROOT/Sources/DashX/GraphQL"

if [ ! -d "$GRAPHQL_DIR" ]; then
  echo "error: $GRAPHQL_DIR not found (run after codegen from repo root)" >&2
  exit 1
fi

patched=0
skipped=0

while IFS= read -r -d '' f; do
  if grep -q "@_implementationOnly import ApolloAPI" "$f"; then
    skipped=$((skipped + 1))
    continue
  fi

  if grep -qE "^(@_exported )?import ApolloAPI$" "$f"; then
    perl -i -pe '
      s{^\@_exported import ApolloAPI$}{\@_implementationOnly import ApolloAPI};
      s{^import ApolloAPI$}{\@_implementationOnly import ApolloAPI};
    ' "$f"
    patched=$((patched + 1))
  fi
done < <(find "$GRAPHQL_DIR" -name "*.swift" -print0)

echo "✓ implementation-only imports applied — patched $patched, skipped $skipped (already rewritten)"
