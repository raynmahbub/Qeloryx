#!/usr/bin/env bash
# Run repository lint and lightweight architecture checks.
set -euo pipefail

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "SwiftLint is required. Install it with: brew install swiftlint" >&2
  exit 1
fi
swiftlint lint --strict

if grep -R -n --include='*.swift' 'import SwiftUI' Core/; then
  echo "SwiftUI imports are not expected in Core/." >&2
  exit 1
fi
if grep -R -n --include='*.swift' 'import AVFoundation' Features/; then
  echo "AVFoundation imports are not expected in Features/." >&2
  exit 1
fi

echo "Lint and architecture checks passed."
