#!/bin/bash

# Heimdall Setup Script
# This script initializes the vendor directory with opencode

echo "╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  "
echo "╠═╣║╣ ║║║║ ║║╠═╣║  ║  "
echo "╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝"
echo "Initial Setup"
echo "============="
echo ""

# Check if vendor/opencode already exists
if [ -d "vendor/opencode" ]; then
    echo "✓ vendor/opencode already exists"
    echo ""
    read -p "Do you want to update it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Updating vendor/opencode..."
        cd vendor/opencode
        git pull origin main
        cd ../..
    fi
else
    echo "Setting up vendor directory..."
    mkdir -p vendor
    
    echo "Cloning opencode..."
    git clone https://github.com/opencodeco/opencode.git vendor/opencode
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully cloned opencode"
    else
        echo "❌ Failed to clone opencode"
        exit 1
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