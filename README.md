# Heimdall CLI

```
╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦
╠═╣║╣ ║║║║ ║║╠═╣║  ║
╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝
```

> AI-powered CLI assistant with enhanced capabilities

## Overview

Heimdall is a customized version of the opencode CLI featuring:

- 🤖 **AI-Powered Assistance** - Claude, GPT-4, and other models
- ⚡ **Zig Build System** - Fast, reliable builds with intelligent patching
- 🔧 **Smart Patching** - Fuzzy matching and automatic conflict resolution
- 📦 **Clean Architecture** - Vendor management with pristine upstream
- 🎨 **Custom Branding** - Heimdall identity throughout

## Quick Start

### Prerequisites

- Zig compiler (0.11.0 or later)
- Git
- Bun runtime (optional, for JavaScript dependencies)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/heimdall.git
cd heimdall

# Run setup (initializes vendor directory and builds)
bash setup.sh

# Or manually:
# 1. Clone opencode
git clone https://github.com/opencodeco/opencode.git vendor/opencode

# 2. Build the system
cd build && zig build && cd ..

# 3. Run the build pipeline
./build/bin/heimdall-build
```

> **Note**: The `vendor/` directory is not included in the repository to keep it lightweight. It will be initialized with fresh opencode source during setup.

## Project Structure

```
heimdall/
├── build/              # Zig-based build system
│   ├── src/           # Source code (Zig)
│   ├── patches/       # Patch definitions (.hpatch.json)
│   ├── config/        # Build configurations
│   └── bin/           # Compiled binaries
├── docs/              # Documentation
│   ├── architecture/  # System design docs
│   ├── development/   # Developer guides
│   └── user/         # User documentation
├── config/           # Application configuration
└── tests/            # Test suites
```

> **Note**: `vendor/opencode/` is git-ignored and pulled fresh during setup

## Build System

Heimdall uses a sophisticated 6-stage build pipeline:

1. **Update** - Pull latest from upstream
2. **Prepare** - Set up build environment
3. **Transform** - Apply patches and branding
4. **Verify** - Check completeness
5. **Build** - Compile binaries
6. **Finalize** - Package and cleanup

### Commands

```bash
# Full build
npm run build

# Dry run (no changes)
npm run build:dry

# Verbose output
npm run build:verbose

# Force through errors
npm run build:force

# Patch management
npm run patch:apply    # Apply patches
npm run patch:verify   # Verify patches
npm run patch:list     # List available patches
npm run patch:create   # Create new patch

# Zig operations
npm run zig:build      # Build Zig binaries
npm run zig:test       # Run Zig tests
```

## Patching System

Heimdall's intelligent patching system features:

- **Fuzzy Matching** - Finds code even when line numbers change
- **Pattern-Based** - Resilient to upstream modifications
- **Fallback Strategies** - Multiple approaches to apply changes
- **Conflict Resolution** - Automatic handling of conflicts

See [docs/architecture/PATCHING_SYSTEM.md](docs/architecture/PATCHING_SYSTEM.md) for details.

## Documentation

- [Architecture](docs/architecture/) - System design and internals
- [Development](docs/development/) - Developer guides
- [User Guide](docs/user/) - Configuration and usage

## Testing

```bash
# Run all tests
npm test

# Specific test suites
npm run test:unit
npm run test:integration
npm run test:patch
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Submit a pull request

## License

MIT License - See LICENSE file for details

## Acknowledgments

Built on top of [opencode](https://github.com/opencodeco/opencode) by the opencode team.
