# Heimdall Build System

Heimdall is a unified build system for transforming OpenCode into a branded, customized version.

## Installation

### From Source
```bash
cd build
zig build -Doptimize=ReleaseFast
```

### Global Installation
```bash
# Copy binaries to packages/heimdall/bin
cp build/zig-out/bin/* packages/heimdall/bin/

# Make available globally
sudo ln -sf $(pwd)/packages/heimdall/bin/heimdall /usr/local/bin/heimdall
```

## Usage

```bash
# Show help
heimdall help

# Run build process
heimdall build

# Preview changes without applying
heimdall build --dry-run

# Apply patches
heimdall patch <patch-file>

# Show version
heimdall version
```

## Binary Locations

- **Development**: `packages/heimdall/bin/`
- **Build Output**: `build/zig-out/bin/`
- **Global Install**: `/usr/local/bin/`

## Commands

### heimdall build
Runs the full build orchestration process:
1. Updates vendor/opencode from upstream
2. Prepares build directory
3. Applies patches and transformations
4. Verifies branding completeness
5. Compiles the final binary
6. Packages the result

### heimdall patch
Applies patches to source files with intelligent matching:
- Exact matching for precise replacements
- Fuzzy matching for flexible patterns
- Context-aware matching for complex scenarios

## Development

Built with Zig for maximum performance and minimal dependencies.

### Building from Source
```bash
cd build
zig build              # Debug build
zig build -Doptimize=ReleaseFast  # Optimized build
zig build test         # Run tests
```

## Version
1.0.0