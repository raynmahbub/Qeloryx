#!/bin/bash
# QELORYX — bootstrap.sh
# Setup development environment

set -e

echo "🎵 QELORYX Bootstrap — Midnight Aurora"
echo "Version: 0.1.0-dev"
echo ""

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode 15+"
    exit 1
fi

echo "✅ Xcode: $(xcodebuild -version | head -n1)"

# Check Swift
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found"
    exit 1
fi

echo "✅ Swift: $(swift --version | head -n1)"

# Install tools
echo ""
echo "📦 Installing tools..."

if ! command -v swiftlint &> /dev/null; then
    echo "Installing SwiftLint..."
    brew install swiftlint || echo "⚠️ Could not install SwiftLint via brew"
else
    echo "✅ SwiftLint: $(swiftlint version)"
fi

if ! command -v xcodegen &> /dev/null; then
    echo "Installing XcodeGen..."
    brew install xcodegen || echo "⚠️ Could not install XcodeGen via brew"
else
    echo "✅ XcodeGen: $(xcodegen --version)"
fi

# Generate project
echo ""
echo "🔨 Generating Xcode project..."
if [ -f "project.yml" ]; then
    xcodegen generate
    echo "✅ Xcode project generated"
else
    echo "⚠️ No project.yml found — using SPM for foundation"
fi

# Swift build
echo ""
echo "🔨 Building SPM modules..."
swift build || echo "⚠️ SPM build failed (expected if no macOS runner)"

echo ""
echo "🎉 Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  - Open Qeloryx.xcodeproj if exists, or Package.swift"
echo "  - Read Docs/ACC/ACC.md for current milestone"
echo "  - Run Tests: swift test"
echo ""
echo "QELORYX — Hear Beyond. Build Beyond."
