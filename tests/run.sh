#!/bin/bash

# Heimdall Test Runner
# Main entry point for all tests

set -e

# Load common utilities
source "$(dirname "$0")/lib/common.sh"

# Parse arguments
MODE="all"
QUICK=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --all)
            MODE="all"
            shift
            ;;
        integration|e2e|unit)
            MODE="$1"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS] [MODE]"
            echo ""
            echo "Modes:"
            echo "  all          Run all tests (default)"
            echo "  integration  Run integration tests only"
            echo "  e2e          Run end-to-end tests only"
            echo "  unit         Run unit tests only (Zig)"
            echo ""
            echo "Options:"
            echo "  --quick      Skip slow tests"
            echo "  --verbose    Show detailed output"
            echo "  --help       Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Header
echo "╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦"
echo "╠═╣║╣ ║║║║ ║║╠═╣║  ║"
echo "╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝"
echo "    TEST SUITE"
echo "========================================="
echo ""
echo "Mode: $MODE"
if $QUICK; then echo "Quick mode: enabled"; fi
if $VERBOSE; then echo "Verbose: enabled"; fi
echo ""

# Setup test environment
setup_test_env

# Track overall results
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# Function to run a test suite
run_suite() {
    local suite_name="$1"
    local test_script="$2"
    
    ((TOTAL_SUITES++))
    
    print_header "Running: $suite_name"
    
    if [ ! -f "$test_script" ]; then
        print_error "Test script not found: $test_script"
        ((FAILED_SUITES++))
        return 1
    fi
    
    if [ ! -x "$test_script" ]; then
        chmod +x "$test_script"
    fi
    
    # Reset counters for this suite
    TESTS_RUN=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_SKIPPED=0
    
    # Run the test
    if $VERBOSE; then
        bash "$test_script"
        RESULT=$?
    else
        bash "$test_script" > "$TEST_TEMP_DIR/output.log" 2>&1
        RESULT=$?
        
        # Show summary from log
        tail -15 "$TEST_TEMP_DIR/output.log" | grep -E "✅|❌|⚠️|PASSED|FAILED|Tests Run" || true
    fi
    
    if [ $RESULT -eq 0 ]; then
        print_success "$suite_name completed successfully"
        ((PASSED_SUITES++))
    else
        print_error "$suite_name failed"
        ((FAILED_SUITES++))
        
        if ! $VERBOSE; then
            echo "Error output (last 20 lines):"
            tail -20 "$TEST_TEMP_DIR/output.log"
        fi
    fi
    
    return $RESULT
}

# Run tests based on mode
case $MODE in
    unit)
        print_header "Unit Tests (Zig)"
        
        if command -v zig &> /dev/null; then
            cd "$PROJECT_ROOT/build"
            if zig build test 2>/dev/null; then
                print_success "Zig unit tests passed"
                ((PASSED_SUITES++))
            else
                print_warning "Zig unit tests need attention"
                ((FAILED_SUITES++))
            fi
            ((TOTAL_SUITES++))
            cd - > /dev/null
        else
            print_warning "Zig not installed - skipping unit tests"
        fi
        ;;
        
    integration)
        print_header "Integration Tests"
        
        for test_script in "$TEST_DIR"/integration/*.test.sh; do
            if [ -f "$test_script" ]; then
                suite_name=$(basename "$test_script" .test.sh)
                run_suite "$suite_name" "$test_script" || true
            fi
        done
        ;;
        
    e2e)
        print_header "End-to-End Tests"
        
        if $QUICK; then
            print_warning "Skipping e2e tests in quick mode"
        else
            for test_script in "$TEST_DIR"/e2e/*.test.sh; do
                if [ -f "$test_script" ]; then
                    suite_name=$(basename "$test_script" .test.sh)
                    run_suite "$suite_name" "$test_script" || true
                fi
            done
        fi
        ;;
        
    all|*)
        # Run all test categories
        
        # Unit tests
        if command -v zig &> /dev/null; then
            print_header "Unit Tests (Zig)"
            cd "$PROJECT_ROOT/build"
            if zig build test 2>/dev/null; then
                print_success "Zig unit tests passed"
                ((PASSED_SUITES++))
            else
                print_warning "Zig unit tests need attention"
                ((FAILED_SUITES++))
            fi
            ((TOTAL_SUITES++))
            cd - > /dev/null
        fi
        
        # Integration tests
        print_header "Integration Tests"
        for test_script in "$TEST_DIR"/integration/*.test.sh; do
            if [ -f "$test_script" ]; then
                suite_name=$(basename "$test_script" .test.sh)
                run_suite "$suite_name" "$test_script" || true
            fi
        done
        
        # E2E tests (skip in quick mode)
        if ! $QUICK; then
            print_header "End-to-End Tests"
            for test_script in "$TEST_DIR"/e2e/*.test.sh; do
                if [ -f "$test_script" ]; then
                    suite_name=$(basename "$test_script" .test.sh)
                    run_suite "$suite_name" "$test_script" || true
                fi
            done
        else
            print_info "Skipping e2e tests in quick mode"
        fi
        ;;
esac

# Final summary
echo ""
echo "========================================="
echo -e "${BOLD}         FINAL SUMMARY${NC}"
echo "========================================="
echo ""
echo -e "Test Suites Run: ${BOLD}$TOTAL_SUITES${NC}"
echo -e "Passed:          ${GREEN}$PASSED_SUITES${NC}"
echo -e "Failed:          ${RED}$FAILED_SUITES${NC}"

if [ $TOTAL_SUITES -gt 0 ]; then
    PASS_RATE=$(( (PASSED_SUITES * 100) / TOTAL_SUITES ))
    echo -e "Pass Rate:       ${BOLD}${PASS_RATE}%${NC}"
fi

echo ""

if [ $FAILED_SUITES -eq 0 ] && [ $PASSED_SUITES -gt 0 ]; then
    echo -e "${GREEN}${BOLD}✅ ALL TESTS PASSED!${NC}"
    exit 0
elif [ $FAILED_SUITES -gt 0 ]; then
    echo -e "${RED}${BOLD}❌ SOME TESTS FAILED${NC}"
    echo ""
    echo "To debug failures, run with --verbose:"
    echo "  $0 --verbose"
    exit 1
else
    echo -e "${YELLOW}${BOLD}⚠️  NO TESTS EXECUTED${NC}"
    exit 1
fi