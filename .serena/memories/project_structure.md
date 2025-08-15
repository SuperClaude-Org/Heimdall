# Heimdall Project Structure

## Root Directory
```
heimdall/
├── build/              # Zig-based build system
├── config/             # Application configuration files
├── docs/               # Documentation
├── tests/              # Test suites and test data
├── vendor/             # External dependencies (git-ignored)
├── .gitignore          # Git ignore rules
├── CHANGELOG.md        # Version history
├── LICENSE             # MIT License
├── README.md           # Project overview and quick start
├── package.json        # Node.js dependencies and scripts
├── setup.sh            # Initial setup script
├── test_complete_setup.sh  # Integration test script
└── tsconfig.json       # TypeScript configuration
```

## Build System (`build/`)
```
build/
├── bin/                # Compiled binaries
│   ├── heimdall-build  # Build orchestrator
│   └── heimdall-patcher # Patch management tool
├── config/             # Build configurations
│   ├── branding.yaml   # Branding configuration
│   └── build.yaml      # Build pipeline config
├── patches/            # Patch definitions
│   ├── ascii-art-branding.hpatch.json
│   ├── enhanced-rules.hpatch.json
│   └── heimdall-branding.hpatch.json
├── src/                # Zig source code
│   ├── matchers/       # Matching strategies
│   │   ├── context.zig # Context-aware matching
│   │   ├── exact.zig   # Exact string matching
│   │   └── fuzzy.zig   # Fuzzy matching
│   ├── build.zig       # Build orchestrator
│   ├── config.zig      # Configuration parser
│   ├── git.zig         # Git operations
│   ├── main.zig        # Entry point
│   ├── patch_format.zig # Patch format definitions
│   ├── patcher.zig     # Core patching logic
│   ├── reporter.zig    # Progress reporting
│   ├── transformer.zig # Code transformations
│   └── verifier.zig    # Verification logic
├── build.zig           # Zig build configuration
└── README.md           # Build system documentation
```

## Configuration (`config/`)
```
config/
├── heimdall.json       # Main application config
└── schema.json         # Configuration schema
```

## Documentation (`docs/`)
```
docs/
├── architecture/       # System design documentation
│   ├── BUILD_SYSTEM.md
│   ├── PATCHING_SYSTEM.md
│   └── VENDOR_MANAGEMENT.md
├── development/        # Developer guides
│   ├── AGENTS.md
│   ├── AGENTS_DISCOVERY.md
│   ├── BUILD.md
│   ├── ENHANCED_RULES.md
│   ├── LOGGING.md
│   └── TESTING.md
└── user/              # User documentation
    └── CONFIGURATION.md
```

## Tests (`tests/`)
```
tests/
├── rules/             # Rule test files
│   ├── docs/
│   │   ├── api.rules.md
│   │   └── style.rules.md
│   ├── global/
│   │   └── global-rules.md
│   └── project/
│       ├── critical.md
│       ├── disabled.md
│       └── extra-instructions.md
└── heimdall-rules-test.json  # Test configuration
```

## Vendor Directory (Git-Ignored)
```
vendor/                # Not in repository
└── opencode/         # Cloned during setup
    ├── packages/     # Opencode packages
    ├── src/          # Source code
    └── ...           # Other opencode files
```

## Build Artifacts (Git-Ignored)
```
.build/               # Temporary build directory
dist/                 # Distribution files
node_modules/         # Node.js dependencies
.zig-cache/          # Zig build cache
```

## Key File Purposes

### Configuration Files
- `heimdall.json` - Runtime configuration for the CLI
- `package.json` - Node.js project definition and scripts
- `tsconfig.json` - TypeScript compiler configuration
- `build.yaml` - Build pipeline configuration
- `branding.yaml` - Branding customization settings

### Scripts
- `setup.sh` - Initializes vendor directory and builds system
- `test_complete_setup.sh` - Full integration test
- `heimdall-build` - Main build orchestrator
- `heimdall-patcher` - Patch management tool

### Documentation
- `README.md` - Project overview and quick start
- `CHANGELOG.md` - Version history and changes
- Architecture docs - System design and internals
- Development docs - How to develop and test
- User docs - How to configure and use