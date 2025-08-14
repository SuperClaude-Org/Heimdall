#!/bin/bash

# Heimdall Update Script
# Updates vendor while preserving customizations via patches

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "================================"
echo "Heimdall Update Process"
echo "================================"
echo ""

# Step 1: Check for uncommitted changes
echo "1. Checking for uncommitted changes..."
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Warning: You have uncommitted changes."
    echo "   Please commit or stash them before updating."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 2: Revert any applied patches
echo ""
echo "2. Reverting applied patches..."
if node "$SCRIPT_DIR/patch-manager.js" revert; then
    echo "✓ Patches reverted"
else
    echo "⚠️  Some patches could not be reverted"
fi

# Step 3: Pull latest opencode
echo ""
echo "3. Pulling latest opencode from upstream..."
git fetch opencode dev
BEFORE_COMMIT=$(git rev-parse HEAD)
git subtree pull --prefix=vendor/opencode opencode dev --squash -m "Update opencode vendor to latest"
AFTER_COMMIT=$(git rev-parse HEAD)

if [ "$BEFORE_COMMIT" = "$AFTER_COMMIT" ]; then
    echo "✓ Already up to date"
else
    echo "✓ Updated vendor/opencode"
    
    # Show what changed
    echo ""
    echo "Changes in this update:"
    git diff --stat "$BEFORE_COMMIT" "$AFTER_COMMIT" vendor/
fi

# Step 4: Verify and reapply patches
echo ""
echo "4. Verifying patches..."
if node "$SCRIPT_DIR/patch-manager.js" verify; then
    echo "✓ All patches can be applied cleanly"
    
    echo ""
    echo "5. Reapplying patches..."
    node "$SCRIPT_DIR/patch-manager.js" apply
else
    echo "⚠️  Some patches need manual resolution"
    echo "   Please review and update the patches in patches/"
    
    # Try to apply what we can
    echo ""
    echo "5. Attempting to apply compatible patches..."
    node "$SCRIPT_DIR/patch-manager.js" apply
fi

# Step 6: Check overrides compatibility
echo ""
echo "6. Checking override compatibility..."
OVERRIDES_DIR="$ROOT_DIR/src/overrides/opencode"
if [ -d "$OVERRIDES_DIR" ]; then
    echo "Found overrides:"
    find "$OVERRIDES_DIR" -type f -name "*.ts" -o -name "*.js" | while read -r override; do
        relative_path="${override#$OVERRIDES_DIR/}"
        vendor_file="$ROOT_DIR/vendor/opencode/$relative_path"
        
        if [ -f "$vendor_file" ]; then
            echo "  ✓ $relative_path (vendor file exists)"
        else
            echo "  ⚠️  $relative_path (vendor file missing - may have been moved/deleted)"
        fi
    done
else
    echo "No overrides found"
fi

# Step 7: Test the build
echo ""
echo "7. Testing Heimdall build..."
if bun install > /dev/null 2>&1; then
    echo "✓ Dependencies installed"
else
    echo "⚠️  Failed to install dependencies"
fi

# Step 8: Run basic test
echo ""
echo "8. Running basic functionality test..."
if "$ROOT_DIR/bin/heimdall" --version > /dev/null 2>&1; then
    VERSION=$("$ROOT_DIR/bin/heimdall" --version 2>&1 | head -1)
    echo "✓ Heimdall is working: $VERSION"
else
    echo "⚠️  Heimdall failed to start"
    echo "   Please check the logs for errors"
fi

# Step 9: Summary
echo ""
echo "================================"
echo "Update Summary"
echo "================================"

# Check if there were any warnings
if grep -q "⚠️" /tmp/heimdall-update.log 2>/dev/null; then
    echo "Status: Completed with warnings"
    echo ""
    echo "Action items:"
    echo "  1. Review patches that failed to apply"
    echo "  2. Check overrides for compatibility"
    echo "  3. Test all custom functionality"
else
    echo "Status: Successfully updated!"
    echo ""
    echo "Next steps:"
    echo "  1. Test your custom commands and features"
    echo "  2. Commit the update: git commit -am 'Update opencode vendor'"
fi

echo ""
echo "For more details, check:"
echo "  - Patches: $ROOT_DIR/patches/"
echo "  - Overrides: $ROOT_DIR/src/overrides/"
echo "  - Extensions: $ROOT_DIR/src/extensions/"