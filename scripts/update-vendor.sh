#!/bin/bash

# Update vendor script for Heimdall
# This script pulls the latest opencode changes and applies rebranding

set -e

echo "Updating opencode vendor dependency..."
echo ""

# Fetch latest from opencode
echo "Fetching latest opencode changes..."
git fetch opencode dev

# Pull changes into subtree
echo "Merging changes into vendor/opencode..."
git subtree pull --prefix=vendor/opencode opencode dev --squash -m "Update opencode vendor to latest"

# Run rebranding
echo ""
echo "Running rebranding script..."
if [ -f "scripts/rebrand.js" ]; then
    node scripts/rebrand.js
else
    echo "Warning: Rebranding script not found, skipping..."
fi

# Check if we have bun installed
if command -v bun &> /dev/null; then
    echo ""
    echo "Installing dependencies..."
    bun install
    
    # Run tests if they exist
    if [ -f "package.json" ] && grep -q '"test"' package.json; then
        echo ""
        echo "Running tests..."
        bun test || echo "Warning: Some tests failed"
    fi
else
    echo "Warning: Bun not installed, skipping dependency installation and tests"
fi

echo ""
echo "Vendor update complete!"
echo "Please review changes and commit if everything looks good."