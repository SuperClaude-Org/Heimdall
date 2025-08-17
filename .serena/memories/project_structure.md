# Project Structure

## Root Directory
```
heimdall_patcher/
├── README.md              # Project documentation
├── LICENSE                # MIT license
├── VERSION                # Current version (1.0.0)
├── package.json           # npm configuration and scripts
├── setup.sh               # Initialization script
├── tsconfig.json          # TypeScript configuration
├── CHANGELOG.md           # Version history
└── .gitignore             # Git ignore patterns
```

## Build System (`build/`)
```
build/
├── build.zig              # Main Zig build configuration
├── README.md              # Build system documentation
├── bin/                   # Compiled binaries
│   ├── heimdall           # Main CLI binary
│   ├── heimdall-patcher   # Patch management tool
│   └── heimdall-build     # Build orchestrator
├── src/                   # Zig source code
│   ├── main.zig           # Main entry point
│   ├── build.zig          # Build orchestrator
│   ├── patcher.zig        # Core patching engine
│   ├── patch_format.zig   # Patch file parsing
│   ├── config.zig         # Configuration management
│   ├── transformer.zig    # Code transformation
│   ├── verifier.zig       # Branding verification
│   ├── git.zig            # Git operations
│   ├── reporter.zig       # Progress reporting
│   └── matchers/          # Pattern matching strategies
│       ├── exact.zig      # Exact string matching
│       ├── fuzzy.zig      # Fuzzy/similarity matching
│       └── context.zig    # Context-aware matching
├── patches/               # Patch definitions
│   ├── heimdall-branding.hpatch.json    # Main branding patch
│   └── ascii-art-branding.hpatch.json   # ASCII art additions
└── config/                # Build configurations
    ├── build.yaml         # Build pipeline settings
    └── branding.yaml      # Branding transformation rules
```

## Configuration (`config/`)
- Application-level configuration files
- Runtime settings and environment variables

## Vendor Directory (`vendor/` - Git Ignored)
```
vendor/
└── opencode/              # Fresh clone of upstream opencode
    ├── packages/          # Upstream package structure
    ├── src/              # Source code to be patched
    └── ...               # All upstream files
```

## Key Files
- **setup.sh**: Initializes vendor/opencode and builds Zig binaries
- **package.json**: Contains npm scripts for build orchestration
- **build/patches/*.hpatch.json**: JSON-based patch definitions
- **build/config/branding.yaml**: Branding transformation configuration
- **VERSION**: Current project version for releases

## Build Artifacts (Generated)
- `build/bin/heimdall-*`: Compiled Zig binaries
- `.zig-cache/`: Zig compilation cache
- `dist/`: Final build output
- `node_modules/`: JavaScript dependencies