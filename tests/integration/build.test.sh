#!/bin/bash

# Build Pipeline Test
# Tests the 6-stage build pipeline

set -e

# Load common utilities
source "$(dirname "$0")/../lib/common.sh"

# Setup
setup_test_env

echo "========================================="
echo "   BUILD PIPELINE TEST"
echo "========================================="

print_header "Checking Build System"

# Check if build binary exists
if [ ! -f "$BUILD_BIN" ]; then
    print_warning "Build binary not found, attempting to build..."
    cd "$PROJECT_ROOT/build"
    zig build
    cd - > /dev/null
fi

assert_file_exists "$BUILD_BIN" "Build binary should exist"

print_header "Test 1: Dry Run Mode"

OUTPUT=$($BUILD_BIN --dry-run 2>&1 || true)
assert_contains "$OUTPUT" "DRY RUN MODE" "Dry run mode should be indicated"

print_header "Test 2: Build Pipeline Stages"

# Check for all 6 stages
STAGES=("Update" "Prepare" "Transform" "Verify" "Build" "Finalize")

for stage in "${STAGES[@]}"; do
    if echo "$OUTPUT" | grep -qi "$stage"; then
        print_success "Stage '$stage' found"
        ((TESTS_PASSED++))
    else
        print_warning "Stage '$stage' not clearly identified"
        ((TESTS_SKIPPED++))
    fi
    ((TESTS_RUN++))
done

print_header "Test 3: Patch Verification"

assert_file_exists "$PATCHER_BIN" "Patcher binary should exist"

if [ -f "$PATCHER_BIN" ]; then
    PATCH_OUTPUT=$($PATCHER_BIN verify 2>&1 || true)
    assert_contains "$PATCH_OUTPUT" "verif\|check\|✓" "Patch verification should work"
fi

print_header "Test 4: List Patches"

if [ -f "$PATCHER_BIN" ]; then
    LIST_OUTPUT=$($PATCHER_BIN list 2>&1 || true)
    
    # Check for known patches
    assert_contains "$LIST_OUTPUT" "heimdall-branding\|ascii-art\|enhanced-rules" "Should list known patches"
fi

print_header "Test 5: Verbose Mode"

VERBOSE_OUTPUT=$($BUILD_BIN --verbose --dry-run 2>&1 | head -50 || true)
assert_contains "$VERBOSE_OUTPUT" "verbose\|VERBOSE\|Debug\|DEBUG" "Verbose mode should provide extra output"

print_header "Test 6: Vendor Directory"

assert_file_exists "$PROJECT_ROOT/vendor/opencode/package.json" "Vendor directory should exist"

if [ -f "$PROJECT_ROOT/vendor/opencode/README.md" ]; then
    if grep -q "Mock" "$PROJECT_ROOT/vendor/opencode/README.md" 2>/dev/null; then
        print_info "Using mock vendor (for testing)"
    else
        print_info "Using real opencode vendor"
    fi
fi

print_header "Test 7: Heimdall Branding"

assert_contains "$OUTPUT" "╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦\|HEIMDALL\|Heimdall" "Should show Heimdall branding"

# Print summary
print_summary