#!/usr/bin/env bash
# Run repository lint and lightweight architecture checks.
set -euo pipefail

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "SwiftLint is required. Install it with: brew install swiftlint" >&2
  exit 1
fi
swiftlint lint

if grep -R -n --include='*.swift' 'import SwiftUI' Qeloryx/Models/ Qeloryx/Services/ Qeloryx/Utilities/Helpers/ Qeloryx/Utilities/Diagnostics/; then
  echo "SwiftUI imports are not expected in the portable domain (Models/Services/Utilities helpers)." >&2
  exit 1
fi
if grep -R -n --include='*.swift' 'import AVFoundation' Qeloryx/Views/; then
  echo "AVFoundation imports are not expected in Views/." >&2
  exit 1
fi

echo "Lint and architecture checks passed."
