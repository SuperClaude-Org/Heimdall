# Suggested Commands

## Setup and Initialization
```bash
# Initialize vendor directory and build system
bash setup.sh

# Manual vendor setup (if needed)
git clone https://github.com/opencodeco/opencode.git vendor/opencode
```

## Build Commands
```bash
# Full build pipeline
npm run build

# Build variants
npm run build:dry          # Dry run (no changes)
npm run build:verbose      # Verbose output  
npm run build:force        # Force through errors

# Direct Zig operations
npm run zig:build          # Build Zig binaries
npm run zig:test           # Run Zig tests
cd build && zig build      # Manual Zig build
```

## Patch Management
```bash
# Patch operations
npm run patch:apply        # Apply all patches
npm run patch:verify       # Verify patches can be applied
npm run patch:list         # List available patches

# Direct patcher usage
./build/bin/heimdall-patcher apply
./build/bin/heimdall-patcher apply --dry-run --verbose
./build/bin/heimdall-patcher verify patches/heimdall-branding.hpatch.json
./build/bin/heimdall-patcher info patches/ascii-art-branding.hpatch.json
```

## Testing
```bash
# Test suites
npm test                   # Run all tests
npm run test:quick         # Quick test run
npm run test:integration   # Integration tests only
npm run test:unit          # Unit tests only
```

## Development Utilities
```bash
# Cleanup
npm run clean              # Remove build artifacts

# Git operations
git status                 # Check current state
git branch                 # Check current branch

# System commands (Linux)
ls -la                     # List files with details
find . -name "*.zig"       # Find Zig files
grep -r "pattern" .        # Search in files
```

## Build System Binaries
```bash
# After building, these binaries are available:
./build/bin/heimdall-build     # Main build orchestrator
./build/bin/heimdall-patcher   # Patch management tool
./build/bin/heimdall           # CLI binary (if built)
```