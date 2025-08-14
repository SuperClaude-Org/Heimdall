#!/bin/bash
set -e

echo "╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  "
echo "╠═╣║╣ ║║║║ ║║╠═╣║  ║  "
echo "╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝"
echo "=== Building Heimdall ==="
echo ""

# Ensure we're in the right directory
cd "$(dirname "$0")/.."

# Check if patches are applied (at least the ASCII art one)
echo "▶ Checking patches..."
if ! grep -q "heimdall :=" vendor/opencode/packages/tui/internal/tui/tui.go 2>/dev/null; then
    echo "▶ Applying patches..."
    npm run patch:apply || echo "⚠ Some patches failed (continuing anyway)"
fi

# Install dependencies in vendor
echo "▶ Installing vendor dependencies..."
cd vendor/opencode
if command -v bun &> /dev/null; then
    bun install
else
    npm install
fi

# Build vendor
echo "▶ Building vendor/opencode..."
if command -v bun &> /dev/null; then
    bun run build || echo "⚠ Build had issues (continuing)"
else
    npm run build || echo "⚠ Build had issues (continuing)"
fi
cd ../..

# Create dist directory if it doesn't exist
mkdir -p dist

# Create standalone binary (optional)
if command -v bun &> /dev/null; then
    echo "▶ Attempting to create standalone binary..."
    bun build vendor/opencode/packages/opencode/src/index.ts \
        --compile \
        --outfile dist/heimdall-standalone \
        --target=bun 2>/dev/null || echo "⚠ Standalone binary creation skipped"
fi

# Ensure executable
chmod +x bin/heimdall

echo ""
echo "✓ Build complete!"
echo "Run with: ./bin/heimdall"