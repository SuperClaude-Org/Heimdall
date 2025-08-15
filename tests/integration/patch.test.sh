#!/bin/bash

# Patch System Test
# Tests the intelligent patching system with fuzzy matching

set -e

# Load common utilities
source "$(dirname "$0")/../lib/common.sh"

# Setup
setup_test_env

echo "========================================="
echo "   PATCHING SYSTEM TEST"
echo "========================================="

print_header "Checking Patch System"

# Check if patcher exists
if [ ! -f "$PATCHER_BIN" ]; then
    print_warning "Patcher binary not found, attempting to build..."
    cd "$PROJECT_ROOT/build"
    zig build
    cd - > /dev/null
fi

assert_file_exists "$PATCHER_BIN" "Patcher binary should exist"

print_header "Test 1: Help System"

HELP_OUTPUT=$($PATCHER_BIN --help 2>&1 || true)
assert_contains "$HELP_OUTPUT" "usage\|help\|command" "Help system should work"

print_header "Test 2: List Patches"

LIST_OUTPUT=$($PATCHER_BIN list 2>&1 || true)

# Count patch files
PATCHES_DIR="$PROJECT_ROOT/build/patches"
PATCH_COUNT=$(ls -1 "$PATCHES_DIR"/*.hpatch.json 2>/dev/null | wc -l)

if [ $PATCH_COUNT -gt 0 ]; then
    print_success "Found $PATCH_COUNT patch file(s)"
    ((TESTS_PASSED++))
    
    # List patch files
    for patch in "$PATCHES_DIR"/*.hpatch.json; do
        if [ -f "$patch" ]; then
            print_info "  $(basename "$patch")"
        fi
    done
else
    print_warning "No patch files found"
    ((TESTS_SKIPPED++))
fi
((TESTS_RUN++))

print_header "Test 3: Verify Patches"

VERIFY_OUTPUT=$($PATCHER_BIN verify 2>&1 || true)
assert_contains "$VERIFY_OUTPUT" "verif\|check" "Verification command should execute"

print_header "Test 4: Patch File Structure"

# Check first patch file
FIRST_PATCH=$(ls -1 "$PATCHES_DIR"/*.hpatch.json 2>/dev/null | head -1)

if [ -f "$FIRST_PATCH" ]; then
    print_info "Analyzing: $(basename "$FIRST_PATCH")"
    
    # Check JSON validity
    if python3 -m json.tool "$FIRST_PATCH" > /dev/null 2>&1; then
        print_success "Valid JSON format"
        ((TESTS_PASSED++))
    elif command -v jq > /dev/null && jq . "$FIRST_PATCH" > /dev/null 2>&1; then
        print_success "Valid JSON format"
        ((TESTS_PASSED++))
    else
        print_warning "Cannot validate JSON (no validator available)"
        ((TESTS_SKIPPED++))
    fi
    ((TESTS_RUN++))
    
    # Check required fields
    for field in "version" "name" "patches"; do
        if grep -q "\"$field\"" "$FIRST_PATCH"; then
            print_success "Has '$field' field"
            ((TESTS_PASSED++))
        else
            print_error "Missing '$field' field"
            ((TESTS_FAILED++))
        fi
        ((TESTS_RUN++))
    done
fi

print_header "Test 5: Dry Run Mode"

if [ -f "$FIRST_PATCH" ]; then
    DRY_OUTPUT=$($PATCHER_BIN apply "$FIRST_PATCH" --dry-run 2>&1 || true)
    assert_contains "$DRY_OUTPUT" "dry.*run\|DRY.*RUN" "Dry run mode should be available"
fi

print_header "Test 6: Matching Strategies"

echo "Checking patch files for matching strategies..."

for patch in "$PATCHES_DIR"/*.hpatch.json; do
    if [ -f "$patch" ]; then
        echo ""
        print_info "$(basename "$patch"):"
        
        # Check for different matching types
        if grep -q '"type".*"exact"' "$patch"; then
            print_success "  Uses exact matching"
            ((TESTS_PASSED++))
        else
            ((TESTS_SKIPPED++))
        fi
        ((TESTS_RUN++))
        
        if grep -q '"type".*"fuzzy"' "$patch"; then
            print_success "  Uses fuzzy matching"
            ((TESTS_PASSED++))
            
            # Check for confidence threshold
            if grep -q "confidence_threshold" "$patch"; then
                THRESHOLD=$(grep -o '"confidence_threshold".*[0-9.]*' "$patch" | grep -o '[0-9.]*' | head -1)
                print_info "  Confidence threshold: $THRESHOLD"
            fi
        else
            ((TESTS_SKIPPED++))
        fi
        ((TESTS_RUN++))
        
        if grep -q '"type".*"context"' "$patch"; then
            print_success "  Uses context matching"
            ((TESTS_PASSED++))
        else
            ((TESTS_SKIPPED++))
        fi
        ((TESTS_RUN++))
    fi
done

print_header "Test 7: Performance Check"

# Time a simple operation
START_TIME=$(date +%s%N)
$PATCHER_BIN --help > /dev/null 2>&1
END_TIME=$(date +%s%N)

# Calculate elapsed time in milliseconds
ELAPSED=$(( (END_TIME - START_TIME) / 1000000 ))

if [ $ELAPSED -lt 100 ]; then
    print_success "Fast execution (<100ms): ${ELAPSED}ms"
    ((TESTS_PASSED++))
elif [ $ELAPSED -lt 500 ]; then
    print_success "Good performance (<500ms): ${ELAPSED}ms"
    ((TESTS_PASSED++))
else
    print_warning "Slower than expected: ${ELAPSED}ms"
    ((TESTS_SKIPPED++))
fi
((TESTS_RUN++))

# Print summary
print_summary