# Heimdall Project Structure

## Directory Layout

```
heimdall/
├── bin/                    # Executable
│   └── heimdall           # Main launcher script
├── config/                 # Configuration files
│   ├── heimdall.example.json  # Example configuration
│   └── schema.json        # JSON schema for validation
├── docs/                   # Documentation
│   ├── AGENTS_DISCOVERY.md    # Rules discovery system
│   ├── CONFIG_SCHEMA.md       # Configuration details
│   ├── ENHANCED_RULES.md      # Enhanced rules system
│   ├── LOGGING.md             # Logging documentation
│   ├── TESTING.md             # Testing guide
│   └── VENDOR_MANAGEMENT.md   # Vendor management guide
├── patches/                # Git patches for customizations
│   ├── 001-heimdall-complete-branding.patch
│   ├── 002-enhanced-agents-discovery.patch
│   └── README.md          # Patch documentation
├── scripts/                # Build and maintenance scripts
│   ├── build.sh           # Build script
│   ├── create-patch.sh    # Create new patches
│   ├── patch-manager.js   # Patch management tool
│   ├── test.sh            # Test suite
│   └── update.sh          # Update from upstream
├── src/                    # Source code extensions
│   └── extensions/        # Heimdall-specific extensions
│       ├── commands/      # Custom commands
│       └── index.ts       # Extension entry point
├── test/                   # Test files and fixtures
│   ├── rules/             # Test rule files
│   └── heimdall-rules-test.json
├── vendor/                 # Vendored dependencies
│   └── opencode/          # Clean opencode vendor
├── .gitignore             # Git ignore patterns
├── AGENTS.md              # Main rules file (at root for discovery)
├── Heimdall.md            # Project branding and info
├── LICENSE                # MIT License
├── package.json           # Node.js package manifest
├── README.md              # Project documentation
├── STRUCTURE.md           # This file
└── tsconfig.json          # TypeScript configuration
```

## Key Principles

1. **Clean Separation**: Vendor code is never modified directly
2. **Patch-Based Customization**: All changes via git patches
3. **Organized Structure**: Clear directory purposes
4. **Maintainable**: Easy to update and extend

## Quick Commands

```bash
# Run Heimdall
npm run dev

# Run tests
npm test

# Build project
npm run build

# Manage patches
npm run patch:apply    # Apply all patches
npm run patch:revert   # Revert all patches
npm run patch:create   # Create new patch
npm run patch:list     # List patches

# Update from upstream
npm run update
```

## Configuration

- Example config: `config/heimdall.example.json`
- Schema: `config/schema.json`
- User config: `heimdall.json` (in project root, gitignored)

## Development Workflow

1. Make changes to vendor files for customization
2. Create patch: `npm run patch:create`
3. Test changes: `npm test`
4. Commit patch file to git

## Updating from Upstream

```bash
npm run update
```

This will:
1. Revert all patches
2. Pull latest opencode
3. Reapply patches
4. Report any conflicts