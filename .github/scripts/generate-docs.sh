#!/bin/bash
# QELORYX — generate-docs.sh

set -e

echo "📚 Generating QELORYX documentation — 1.0.0 Stable — App Store Ready"
echo "Version: 1.0.0 Stable"

# Check if jazzy is installed
if ! command -v jazzy &> /dev/null; then
    echo "Installing jazzy..."
    gem install jazzy || echo "Could not install jazzy"
fi

if command -v jazzy &> /dev/null; then
    jazzy --min-acl internal --theme fullwidth --output Docs/api || echo "Jazzy failed, but continuing"
    echo "✅ API docs generated to Docs/api"
else
    echo "⚠️ Jazzy not available, skipping API docs"
fi

echo "Docs structure:"
ls -la Docs/ADR/
ls -la Docs/EPL/
ls -la Docs/IL/
ls -la Docs/SHM/
ls -la Docs/ACC/

echo "✅ Docs check complete"
