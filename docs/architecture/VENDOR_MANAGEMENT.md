# Vendor Management Guide

## Overview

Heimdall maintains a clean separation between the upstream opencode source and customizations. The vendor directory (`vendor/opencode/`) is git-ignored and pulled fresh during setup, while customizations are applied through an intelligent Zig-based patching system.

## Architecture

```
heimdall/
├── vendor/                  # Git-ignored, pulled fresh
│   └── opencode/           # Pristine opencode source
├── build/                  # Zig-based build system
│   ├── patches/            # Patch definitions (.hpatch.json)
│   │   ├── ascii-art-branding.hpatch.json
│   │   ├── enhanced-rules.hpatch.json
│   │   └── heimdall-branding.hpatch.json
│   ├── src/               # Patcher source code (Zig)
│   └── bin/               # Compiled binaries
│       ├── heimdall-build  # Build orchestrator
│       └── heimdall-patcher # Patch management
└── .build/                 # Temporary build directory
    └── heimdall/          # Transformed source
```

## Build Pipeline

The 6-stage build pipeline handles vendor management:

1. **Update** - Pull latest from upstream repository
2. **Prepare** - Copy vendor to clean build directory
3. **Transform** - Apply patches with intelligent matching
4. **Verify** - Check branding completeness
5. **Build** - Compile the application
6. **Finalize** - Package and cleanup

## Working with Patches

### Patch Format (.hpatch.json)

Heimdall uses JSON-based patch files with intelligent matching:

```json
{
  "version": "1.0",
  "name": "heimdall-branding",
  "description": "Replace OpenCode branding with Heimdall",
  "patches": [
    {
      "id": "update-package-name",
      "files": ["package.json"],
      "changes": [
        {
          "strategy": "replace",
          "matchers": [
            {
              "type": "exact",
              "pattern": "\"name\": \"opencode\""
            },
            {
              "type": "fuzzy",
              "pattern": "name.*opencode",
              "confidence_threshold": 0.8
            }
          ],
          "replacement": "\"name\": \"heimdall\""
        }
      ]
    }
  ]
}
```

### Apply Patches
```bash
# Apply all patches
npm run patch:apply
./build/bin/heimdall-patcher apply

# Apply specific patch
./build/bin/heimdall-patcher apply build/patches/heimdall-branding.hpatch.json

# Dry run to preview changes
./build/bin/heimdall-patcher apply --dry-run
```

### Verify Patches
```bash
# Check if patches can be applied
npm run patch:verify
./build/bin/heimdall-patcher verify

# Verify specific patch
./build/bin/heimdall-patcher verify build/patches/enhanced-rules.hpatch.json
```

### List Patches
```bash
# List all available patches
npm run patch:list
./build/bin/heimdall-patcher list
```

### Create New Patch
```bash
# Interactive patch creation (future feature)
npm run patch:create
./build/bin/heimdall-patcher create

# Manual creation: Create .hpatch.json file in build/patches/
```

## Matching Strategies

The patcher supports multiple matching strategies with fallbacks:

### 1. Exact Matching
```json
{
  "type": "exact",
  "pattern": "opencode"
}
```

### 2. Fuzzy Matching
```json
{
  "type": "fuzzy",
  "pattern": "open.*code",
  "confidence_threshold": 0.7
}
```

### 3. Context Matching
```json
{
  "type": "context",
  "context": "last_import"  // or: first_import, last_function, class_start
}
```

## Updating Vendor

### Automatic Update
```bash
# Full build includes vendor update
npm run build
./build/bin/heimdall-build
```

### Manual Update
```bash
# Update vendor from upstream
cd vendor/opencode
git pull origin main
cd ../..

# Rebuild with patches
npm run build
```

### Fresh Setup
```bash
# Complete fresh setup
bash setup.sh

# Or manually:
rm -rf vendor/opencode
git clone https://github.com/opencodeco/opencode.git vendor/opencode
cd build && zig build && cd ..
./build/bin/heimdall-build
```

## Best Practices

1. **Never commit vendor/** - It's git-ignored for a reason
2. **Use multiple matchers** - Provide fallbacks for resilience
3. **Test patches after updates** - Upstream changes may affect matching
4. **Keep patches focused** - One logical change per patch
5. **Document patches** - Clear descriptions in .hpatch.json files
6. **Use confidence thresholds** - Balance between strict and flexible matching

## Troubleshooting

### Patch Won't Apply

1. **Check matcher patterns**:
```bash
./build/bin/heimdall-patcher verify patches/problem.hpatch.json --verbose
```

2. **Try different strategies**:
- Add fuzzy matcher with lower confidence
- Use context-based matching
- Add multiple exact patterns

3. **Examine the target file**:
```bash
# See what the patcher is trying to match
cat vendor/opencode/target-file.js | grep -C 3 "pattern"
```

### After Update Conflicts

1. **Run verification**:
```bash
./build/bin/heimdall-patcher verify --verbose
```

2. **Update patterns if needed**:
- Adjust fuzzy matching confidence
- Add new fallback matchers
- Update exact patterns

3. **Test in dry-run mode**:
```bash
./build/bin/heimdall-build --dry-run
```

## Current Patches

### ascii-art-branding.hpatch.json
- Updates ASCII art throughout the application
- Changes from OpenCode logo to Heimdall branding

### heimdall-branding.hpatch.json
- Updates package name and references
- Changes CLI name from "opencode" to "heimdall"
- Updates configuration file names

### enhanced-rules.hpatch.json
- Adds enhanced rules system support
- Implements priority-based rule loading
- Adds validation and size limits

## Performance

The Zig-based patcher provides:
- **Native performance**: 10-100x faster than JS-based patching
- **Low memory usage**: < 10MB for typical operations
- **Near-instant application**: < 100ms for most patches
- **Parallel processing**: Multiple files patched simultaneously

## Adding New Features

For completely new functionality (not modifications):

1. **Create new source files** in appropriate directories
2. **Add build configuration** if needed
3. **No patches required** for new files

For modifications to vendor code:

1. **Identify target files** in vendor/opencode
2. **Create .hpatch.json** in build/patches/
3. **Test with multiple matchers** for resilience
4. **Verify with dry-run** before applying

## Security Considerations

- Vendor directory is never committed (prevents supply chain issues)
- Patches are version controlled and reviewable
- Build process is deterministic and reproducible
- No arbitrary code execution in patch files