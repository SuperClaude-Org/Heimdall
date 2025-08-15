# Heimdall Test Suite

## Overview

Clean, organized test structure for the Heimdall CLI project.

## Structure

```
tests/
├── fixtures/              # Test data (non-executable)
│   ├── rules/            # Rule files for testing
│   │   ├── 10-global.md          # Priority 10
│   │   ├── 30-instructions.md    # Priority 30
│   │   ├── 50-api.md             # Priority 50
│   │   ├── 50-style.md           # Priority 50
│   │   ├── 90-critical.md        # Priority 90
│   │   └── xx-disabled.md        # Disabled rule
│   └── config.json               # Test configuration
├── integration/                  # Integration tests
│   ├── build.test.sh            # Build pipeline test
│   ├── patch.test.sh            # Patch system test
│   └── rules.test.sh            # Rules loading test
├── e2e/                         # End-to-end tests
│   └── setup.test.sh            # Complete setup test
├── lib/                         # Shared utilities
│   └── common.sh                # Common test functions
├── run.sh                       # Main test runner
└── README.md                    # This file
```

## Running Tests

### Quick Start

```bash
# Run all tests
npm test

# Run with options
./tests/run.sh --quick      # Skip slow tests
./tests/run.sh --verbose    # Show detailed output
./tests/run.sh --all        # Run everything (default)
```

### Test Categories

```bash
# Integration tests only
./tests/run.sh integration

# End-to-end tests only
./tests/run.sh e2e

# Unit tests only (Zig)
./tests/run.sh unit
```

### NPM Scripts

```bash
npm test              # Run all tests
npm run test:quick    # Quick test run
npm run test:integration  # Integration tests
npm run test:e2e      # End-to-end tests
```

## Test Files

### Fixtures (`fixtures/`)

Test data files with priority-based naming:
- `10-global.md` - Low priority (loads first)
- `30-instructions.md` - From instructions field
- `50-*.md` - Default priority (glob pattern test)
- `90-critical.md` - High priority (loads last)
- `xx-disabled.md` - Should not load

### Integration Tests (`integration/`)

- **build.test.sh** - Tests 6-stage build pipeline
- **patch.test.sh** - Tests intelligent patching system
- **rules.test.sh** - Tests enhanced rules loading

### End-to-End Tests (`e2e/`)

- **setup.test.sh** - Tests complete setup from fresh clone

### Shared Library (`lib/`)

- **common.sh** - Shared functions and utilities
  - Color output functions
  - Assertion helpers
  - Test counters
  - Environment setup

## Writing Tests

### Test Structure

```bash
#!/bin/bash

# Test description
set -e

# Load common utilities
source "$(dirname "$0")/../lib/common.sh"

# Setup
setup_test_env

# Test header
echo "========================================="
echo "   TEST NAME"
echo "========================================="

# Tests
print_header "Test 1: Description"
assert_equals "expected" "actual" "Test message"

print_header "Test 2: Description"
assert_contains "$OUTPUT" "pattern" "Should contain pattern"

# Summary
print_summary
```

### Available Assertions

```bash
assert_equals "expected" "actual" "message"
assert_contains "haystack" "needle" "message"
assert_file_exists "path" "message"
assert_command_succeeds "command" "message"
```

### Helper Functions

```bash
print_success "message"    # Green checkmark
print_error "message"      # Red X
print_warning "message"    # Yellow warning
print_info "message"       # Blue info
print_header "title"       # Section header
```

## Test Coverage

### ✅ Implemented
- Rule priority system
- Rule enable/disable
- Glob pattern matching
- Build pipeline stages
- Patch application
- Configuration validation
- Setup process

### 🔄 Planned
- MCP server integration
- Agent configuration
- Keybinding system
- Formatter integration
- LSP integration
- Permission system
- Hooks system

## Manual Testing

For features not covered by automated tests:

1. **Interactive Features**
   - TUI navigation
   - Agent switching
   - Model selection

2. **External Dependencies**
   - API key validation
   - Network requests
   - MCP server connections

3. **Performance**
   - Large file handling
   - Memory usage
   - Response times

## Troubleshooting

### Common Issues

**Tests not running:**
- Check file permissions: `chmod +x tests/**/*.sh`
- Verify prerequisites: `cd build && zig build`

**Missing dependencies:**
- Run setup: `bash setup.sh`
- Build binaries: `cd build && zig build`

**Test failures:**
- Run with verbose: `./tests/run.sh --verbose`
- Check specific test: `bash tests/integration/build.test.sh`

### Debug Mode

```bash
# Enable debug output
export DEBUG=1
./tests/run.sh --verbose

# Check test structure
ls -la tests/**/*.sh
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: goto-bus-stop/setup-zig@v1
      - run: bash setup.sh
      - run: npm test
```

## Contributing

### Adding Tests

1. Choose appropriate directory:
   - `integration/` for component tests
   - `e2e/` for workflow tests

2. Follow naming convention:
   - Test scripts: `*.test.sh`
   - Use descriptive names

3. Use common library:
   - Source `lib/common.sh`
   - Use assertion functions
   - Call `print_summary`

4. Update documentation:
   - Add to test coverage list
   - Document new assertions

### Best Practices

- Keep tests focused and fast
- Use descriptive test names
- Clean up test artifacts
- Provide clear error messages
- Test both success and failure cases
- Use fixtures for test data
- Don't modify production files

## Quick Reference

```bash
# Run all tests
./tests/run.sh

# Quick test (skip slow tests)
./tests/run.sh --quick

# Verbose output
./tests/run.sh --verbose

# Specific category
./tests/run.sh integration
./tests/run.sh e2e

# Individual test
bash tests/integration/build.test.sh

# With npm
npm test
npm run test:quick
```