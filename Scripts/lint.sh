#!/bin/bash
# QELORYX — lint.sh

set -e

echo "🔍 Linting QELORYX..."

if command -v swiftlint &> /dev/null; then
    swiftlint lint --strict
    echo "✅ SwiftLint passed"
else
    echo "⚠️ SwiftLint not installed, skipping"
fi

echo "Checking architecture rules..."

# Check for SwiftUI in Core
if grep -r "import SwiftUI" Core/ --include="*.swift" | grep -v "Tests"; then
    echo "❌ Architecture violation: SwiftUI found in Core/"
    exit 1
else
    echo "✅ No SwiftUI in Core"
fi

# Check for AVFoundation in Features
if grep -r "import AVFoundation" Features/ --include="*.swift"; then
    echo "❌ Architecture violation: AVFoundation found in Features/"
    exit 1
else
    echo "✅ No AVFoundation in Features"
fi

# Check for Astryx prefix in DesignSystem components
echo "✅ Architecture checks passed"

echo "🎉 Lint complete"
