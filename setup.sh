#!/bin/bash

# Heimdall Setup Script
# This script initializes the fork directory with opencode

echo "╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  "
echo "╠═╣║╣ ║║║║ ║║╠═╣║  ║  "
echo "╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝"
echo "Test Setup"
echo "=========="
echo ""

# Check if fork/opencode already exists
if [ -d "fork/opencode" ]; then
  echo "✓ fork/opencode already exists"
  echo ""
  read -p "Do you want to update it? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Updating fork/opencode..."
    cd fork/opencode
    git pull origin main
    cd ../..
  fi
else
  echo "Setting up fork directory..."
  mkdir -p fork

  echo "Cloning opencode..."

  # Try to clone the repository
  if git clone https://github.com/opencodeco/opencode.git fork/opencode 2>/dev/null; then
    echo "✅ Successfully cloned opencode"
  else
    echo "⚠️  Could not clone opencode repository"
    echo "Creating mock fork/opencode for testing..."

    # Create a mock opencode structure for testing
    mkdir -p fork/opencode

    # Create essential mock files
    cat >fork/opencode/package.json <<'EOF'
{
  "name": "opencode",
  "version": "1.0.0",
  "description": "Mock opencode for testing"
}
EOF

    # Create a basic source structure
    mkdir -p fork/opencode/src
    echo "// Mock opencode source" >fork/opencode/src/index.js

    # Create a README
    echo "# Mock Opencode" >fork/opencode/README.md
    echo "This is a mock setup for testing Heimdall build system" >>fork/opencode/README.md

    echo "✅ Created mock fork/opencode for testing"
  fi
fi

# Build Zig binaries
echo ""
echo "Building Heimdall build system..."
cd build
zig build

if [ $? -eq 0 ]; then
  echo "✅ Build system ready"
else
  echo "❌ Build failed"
  echo "Make sure Zig is installed: https://ziglang.org/download/"
  exit 1
fi

cd ..

echo ""
echo "================================"
echo "✅ Setup complete!"
echo "================================"
echo ""
echo "You can now run:"
echo "  ./build/bin/heimdall-build     # Build Heimdall"
echo "  ./build/bin/heimdall-patcher   # Manage patches"
echo ""
echo "Or use npm scripts:"
echo "  npm run build                  # Build Heimdall"
echo "  npm run build:dry              # Dry run"
echo ""
