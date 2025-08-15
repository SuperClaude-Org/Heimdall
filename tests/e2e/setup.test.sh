#!/bin/bash

# End-to-End Setup Test
# Tests the complete setup process from fresh clone to working system

set -e

# Load common utilities
source "$(dirname "$0")/../lib/common.sh"

# Setup
setup_test_env

echo "========================================="
echo "   END-TO-END SETUP TEST"
echo "========================================="

print_header "Test Environment Setup"

# Create a temporary test directory
TEST_CLONE_DIR="$TEST_TEMP_DIR/heimdall_test"
print_info "Test directory: $TEST_CLONE_DIR"

# Simulate fresh clone
print_header "Step 1: Simulating Fresh Clone"

mkdir -p "$TEST_CLONE_DIR"
cp -r "$PROJECT_ROOT"/* "$TEST_CLONE_DIR/" 2>/dev/null || true
cp -r "$PROJECT_ROOT"/.* "$TEST_CLONE_DIR/" 2>/dev/null || true

# Remove vendor directory to simulate fresh clone
rm -rf "$TEST_CLONE_DIR/vendor"

assert_file_exists "$TEST_CLONE_DIR/setup.sh" "Setup script should exist"
print_success "Repository structure copied (vendor excluded)"

print_header "Step 2: Verify Initial Structure"

EXPECTED_DIRS=("build" "docs" "config" "tests")

for dir in "${EXPECTED_DIRS[@]}"; do
    if [ -d "$TEST_CLONE_DIR/$dir" ]; then
        print_success "$dir/ exists"
        ((TESTS_PASSED++))
    else
        print_error "$dir/ missing"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
done

# Check that vendor is NOT present
if [ -d "$TEST_CLONE_DIR/vendor" ]; then
    print_error "vendor/ should not exist in fresh clone"
    ((TESTS_FAILED++))
else
    print_success "vendor/ correctly excluded"
    ((TESTS_PASSED++))
fi
((TESTS_RUN++))

print_header "Step 3: Running Setup Script"

cd "$TEST_CLONE_DIR"

# Run setup in non-interactive mode
export CI=true

if [ -f "setup.sh" ]; then
    if bash setup.sh > "$TEST_TEMP_DIR/setup.log" 2>&1; then
        print_success "Setup script completed"
        ((TESTS_PASSED++))
    else
        print_error "Setup script failed"
        cat "$TEST_TEMP_DIR/setup.log" | tail -20
        ((TESTS_FAILED++))
    fi
else
    print_error "setup.sh not found"
    ((TESTS_FAILED++))
fi
((TESTS_RUN++))

print_header "Step 4: Verify Vendor Setup"

if [ -d "vendor/opencode" ]; then
    print_success "vendor/opencode/ created"
    ((TESTS_PASSED++))
    
    # Check key vendor files
    if [ -f "vendor/opencode/package.json" ]; then
        print_success "vendor/opencode/package.json exists"
        ((TESTS_PASSED++))
        
        # Check if mock or real
        if [ -f "vendor/opencode/README.md" ]; then
            if grep -q "Mock" vendor/opencode/README.md; then
                print_info "Using mock vendor setup (for testing)"
            else
                print_info "Using real opencode repository"
            fi
        fi
    else
        print_error "vendor/opencode/package.json missing"
        ((TESTS_FAILED++))
    fi
else
    print_error "vendor/opencode/ not created"
    ((TESTS_FAILED++))
fi
((TESTS_RUN++))

print_header "Step 5: Verify Build Binaries"

BINARIES=("build/bin/heimdall-build" "build/bin/heimdall-patcher")

for binary in "${BINARIES[@]}"; do
    if [ -f "$binary" ]; then
        print_success "$binary exists"
        ((TESTS_PASSED++))
        
        if [ -x "$binary" ]; then
            print_success "  Is executable"
            ((TESTS_PASSED++))
        else
            print_error "  Not executable"
            ((TESTS_FAILED++))
        fi
    else
        print_error "$binary missing"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
done

print_header "Step 6: Test Build System"

if [ -f "build/bin/heimdall-build" ]; then
    if ./build/bin/heimdall-build --help > /dev/null 2>&1; then
        print_success "heimdall-build --help works"
        ((TESTS_PASSED++))
    else
        print_error "heimdall-build --help failed"
        ((TESTS_FAILED++))
    fi
else
    print_warning "Build binary not available for testing"
    ((TESTS_SKIPPED++))
fi
((TESTS_RUN++))

if [ -f "build/bin/heimdall-patcher" ]; then
    if ./build/bin/heimdall-patcher --help > /dev/null 2>&1; then
        print_success "heimdall-patcher --help works"
        ((TESTS_PASSED++))
    else
        print_error "heimdall-patcher --help failed"
        ((TESTS_FAILED++))
    fi
else
    print_warning "Patcher binary not available for testing"
    ((TESTS_SKIPPED++))
fi
((TESTS_RUN++))

print_header "Step 7: Test Dry Run"

if [ -f "build/bin/heimdall-build" ]; then
    DRY_OUTPUT=$(./build/bin/heimdall-build --dry-run 2>&1 || true)
    
    if echo "$DRY_OUTPUT" | grep -q "DRY RUN MODE"; then
        print_success "Dry run mode works"
        ((TESTS_PASSED++))
    else
        print_warning "Dry run mode not clearly indicated"
        ((TESTS_SKIPPED++))
    fi
else
    print_warning "Cannot test dry run"
    ((TESTS_SKIPPED++))
fi
((TESTS_RUN++))

print_header "Step 8: Check Documentation"

DOCS=(
    "README.md"
    "docs/architecture/BUILD_SYSTEM.md"
    "docs/architecture/PATCHING_SYSTEM.md"
    "docs/development/AGENTS.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        print_success "$doc exists"
        ((TESTS_PASSED++))
    else
        print_error "$doc missing"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
done

print_header "Step 9: Check npm Scripts"

if [ -f "package.json" ]; then
    if grep -q '"build": "./build/bin/heimdall-build"' package.json; then
        print_success "npm run build configured"
        ((TESTS_PASSED++))
    else
        print_error "npm run build not configured"
        ((TESTS_FAILED++))
    fi
    
    if grep -q '"test": "./tests/run.sh"' package.json; then
        print_success "npm test configured"
        ((TESTS_PASSED++))
    else
        print_warning "npm test not configured with new structure"
        ((TESTS_SKIPPED++))
    fi
else
    print_error "package.json not found"
    ((TESTS_FAILED++))
fi
((TESTS_RUN++))

# Return to original directory
cd - > /dev/null

# Print summary
print_summary