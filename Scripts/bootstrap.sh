#!/usr/bin/env bash
# Prepare a local macOS development environment.
set -euo pipefail

for tool in xcodebuild swift brew; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Required tool not found: $tool" >&2
    exit 1
  fi
done

printf 'Xcode: %s\n' "$(xcodebuild -version | head -n 1)"
swift --version

if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi
if ! command -v swiftlint >/dev/null 2>&1; then
  brew install swiftlint
fi

xcodegen generate
swift build
printf '\nEnvironment ready. Run `swift test` and `Scripts/lint.sh` before submitting changes.\n'
