#!/bin/bash

# Common Test Utilities
# Shared functions and variables for all test scripts

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# Paths
export TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
export FIXTURES_DIR="$TEST_DIR/fixtures"
export HEIMDALL_BIN="$PROJECT_ROOT/bin/heimdall"
export BUILD_BIN="$PROJECT_ROOT/build/bin/heimdall-build"
export PATCHER_BIN="$PROJECT_ROOT/build/bin/heimdall-patcher"

# Test counters
export TESTS_RUN=0
export TESTS_PASSED=0
export TESTS_FAILED=0
export TESTS_SKIPPED=0

# Print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BOLD}$1${NC}"
    echo "----------------------------------------"
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    ((TESTS_RUN++))
    if [ "$expected" = "$actual" ]; then
        print_success "$message"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "$message (expected: '$expected', got: '$actual')"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Should contain pattern}"
    
    ((TESTS_RUN++))
    if echo "$haystack" | grep -q "$needle"; then
        print_success "$message"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "$message (pattern '$needle' not found)"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    ((TESTS_RUN++))
    if [ -f "$file" ]; then
        print_success "$message: $file"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "$message: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_command_succeeds() {
    local command="$1"
    local message="${2:-Command should succeed}"
    
    ((TESTS_RUN++))
    if eval "$command" > /dev/null 2>&1; then
        print_success "$message"
        ((TESTS_PASSED++))
        return 0
    else
        print_error "$message: $command"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    local missing=0
    
    if [ ! -f "$BUILD_BIN" ]; then
        print_warning "Build binary not found at $BUILD_BIN"
        print_info "Run: cd build && zig build"
        ((missing++))
    fi
    
    if [ ! -f "$PATCHER_BIN" ]; then
        print_warning "Patcher binary not found at $PATCHER_BIN"
        print_info "Run: cd build && zig build"
        ((missing++))
    fi
    
    if [ ! -d "$PROJECT_ROOT/vendor/opencode" ]; then
        print_warning "Vendor directory not found"
        print_info "Run: bash setup.sh"
        ((missing++))
    fi
    
    return $missing
}

# Print test summary
print_summary() {
    echo ""
    echo "========================================="
    echo -e "${BOLD}         TEST SUMMARY${NC}"
    echo "========================================="
    echo ""
    echo -e "Tests Run:     ${BOLD}$TESTS_RUN${NC}"
    echo -e "Passed:        ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:        ${RED}$TESTS_FAILED${NC}"
    echo -e "Skipped:       ${YELLOW}$TESTS_SKIPPED${NC}"
    
    if [ $TESTS_RUN -gt 0 ]; then
        local pass_rate=$(( (TESTS_PASSED * 100) / TESTS_RUN ))
        echo -e "Pass Rate:     ${BOLD}${pass_rate}%${NC}"
    fi
    
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ] && [ $TESTS_PASSED -gt 0 ]; then
        echo -e "${GREEN}${BOLD}✅ ALL TESTS PASSED!${NC}"
        return 0
    elif [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}${BOLD}❌ SOME TESTS FAILED${NC}"
        return 1
    else
        echo -e "${YELLOW}${BOLD}⚠️  NO TESTS EXECUTED${NC}"
        return 1
    fi
}

# Setup test environment
setup_test_env() {
    # Create temp directory for test outputs
    export TEST_TEMP_DIR="/tmp/heimdall-test-$$"
    mkdir -p "$TEST_TEMP_DIR"
    
    # Trap to clean up on exit
    trap "rm -rf $TEST_TEMP_DIR" EXIT
}

# Run a test with timeout
run_with_timeout() {
    local timeout="$1"
    local command="$2"
    
    timeout "$timeout" bash -c "$command"
}

# Export functions for use in test scripts
export -f print_success
export -f print_error
export -f print_warning
export -f print_info
export -f print_header
export -f assert_equals
export -f assert_contains
export -f assert_file_exists
export -f assert_command_succeeds
export -f check_prerequisites
export -f print_summary
export -f setup_test_env
export -f run_with_timeout