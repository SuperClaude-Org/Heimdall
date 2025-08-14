#!/bin/bash

# Heimdall Test Suite
# Tests various aspects of the Heimdall CLI

set -e

echo "╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  "
echo "╠═╣║╣ ║║║║ ║║╠═╣║  ║  "
echo "╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝"
echo "=== Heimdall Test Suite ==="
echo ""

# Basic functionality tests
echo "▶ Testing basic functionality..."
echo ""

echo "1. Version check:"
./bin/heimdall --version
echo ""

echo "2. Help display (branding check):"
./bin/heimdall --help | head -15
echo ""

echo "3. Configuration file check:"
if [ -f "config/heimdall.example.json" ]; then
    echo "✓ Example config found in config/"
else
    echo "✗ Example config not found"
fi
echo ""

# Command tests
echo "▶ Testing commands..."
echo ""

echo "4. Auth command:"
./bin/heimdall auth --help | head -5
echo ""

echo "5. Agent command:"
./bin/heimdall agent --help | head -5
echo ""

# Rules system tests
if [ -f "test/heimdall-rules-test.json" ]; then
    echo "▶ Testing enhanced rules system..."
    echo ""
    
    echo "6. Default configuration (no rules field):"
    ./bin/heimdall --version > /dev/null 2>&1 && echo "✓ Default config works"
    echo ""
    
    echo "7. Test configuration (with rules field):"
    export HEIMDALL_CONFIG=test/heimdall-rules-test.json
    ./bin/heimdall --version > /dev/null 2>&1 && echo "✓ Rules config works"
    unset HEIMDALL_CONFIG
    echo ""
    
    echo "8. Rule loading logs:"
    if [ -f ~/.local/share/heimdall/log/dev.log ]; then
        tail -50 ~/.local/share/heimdall/log/dev.log | grep -E "(system.rules|loaded rule)" || echo "No rule logs found"
    else
        echo "Log file not found (may not have been created yet)"
    fi
    echo ""
fi

# Patch system tests
echo "▶ Testing patch system..."
echo ""

echo "9. Patch list:"
npm run patch:list
echo ""

# Summary
echo "═══════════════════════════════════════"
echo "✓ All tests complete!"
echo "═══════════════════════════════════════"