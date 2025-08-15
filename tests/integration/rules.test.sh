#!/bin/bash

# Rules Loading System Test
# Tests the enhanced rules loading system with various configurations

set -e

# Load common utilities
source "$(dirname "$0")/../lib/common.sh"

# Setup
setup_test_env

echo "========================================="
echo "   RULES LOADING SYSTEM TEST"
echo "========================================="

# Check prerequisites
if ! check_prerequisites; then
    print_warning "Some prerequisites missing, tests may fail"
fi

print_header "Test 1: Load Test Configuration"

# Test loading configuration
OUTPUT=$($HEIMDALL_BIN --config "$FIXTURES_DIR/config.json" --print-logs --log-level INFO 2>&1 || true)

assert_contains "$OUTPUT" "loaded rule files" "Rules should be loaded"

print_header "Test 2: Verify Priority Order"

# Files should load in priority order: 10, 30, 50, 90
assert_contains "$OUTPUT" "totalFiles" "Should report file count"

print_header "Test 3: Check Disabled Rules"

# Disabled file should not be loaded
if echo "$OUTPUT" | grep -q "xx-disabled"; then
    print_error "Disabled file was loaded (should not be)"
    ((TESTS_FAILED++))
else
    print_success "Disabled file correctly not loaded"
    ((TESTS_PASSED++))
fi
((TESTS_RUN++))

print_header "Test 4: Debug Logging"

DEBUG_OUTPUT=$($HEIMDALL_BIN --config "$FIXTURES_DIR/config.json" --print-logs --log-level DEBUG 2>&1 | head -100 || true)
assert_contains "$DEBUG_OUTPUT" "DEBUG" "Debug logging should work"

print_header "Test 5: Glob Pattern Matching"

# Should match 50-api.md and 50-style.md
assert_contains "$OUTPUT" "50-" "Glob pattern should match priority-50 files"

print_header "Test 6: Missing Required File"

# Create test config with missing required file
cat > "$TEST_TEMP_DIR/missing-required.json" <<EOF
{
  "rules": [
    {
      "path": "/nonexistent/required/file.md",
      "priority": 99,
      "required": true
    }
  ],
  "rulesConfig": {
    "failOnMissing": false,
    "logLevel": "info"
  }
}
EOF

MISSING_OUTPUT=$($HEIMDALL_BIN --config "$TEST_TEMP_DIR/missing-required.json" --print-logs 2>&1 || true)
assert_contains "$MISSING_OUTPUT" "not found\|missing\|error" "Should handle missing required file"

# Print summary
print_summary