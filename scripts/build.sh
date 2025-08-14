#!/bin/bash

echo "=== Building Heimdall CLI ==="
echo ""

# Step 1: Clean vendor (optional, for fresh build)
if [ "$1" == "clean" ]; then
    echo "Step 1: Cleaning vendor directory..."
    git checkout vendor/ 2>/dev/null || true
    echo "✓ Vendor cleaned"
    echo ""
fi

# Step 2: Install dependencies
echo "Step 2: Installing dependencies..."
npm install
echo "✓ Dependencies installed"
echo ""

# Step 3: Apply patches
echo "Step 3: Applying patches..."
npm run patch:apply
echo "✓ Patches applied"
echo ""

# Step 4: Make binary executable
echo "Step 4: Setting executable permissions..."
chmod +x bin/heimdall
echo "✓ Binary is executable"
echo ""

# Step 5: Verify build
echo "Step 5: Verifying build..."
if ./bin/heimdall --version > /dev/null 2>&1; then
    echo "✓ Build successful!"
    echo ""
    echo "Version: $(./bin/heimdall --version)"
else
    echo "✗ Build failed!"
    exit 1
fi

echo ""
echo "=== Build complete! ==="
echo ""
echo "You can now run: ./bin/heimdall --help"