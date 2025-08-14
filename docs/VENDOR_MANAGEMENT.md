# Vendor Management Guide

## Overview

Heimdall uses Git subtree to vendor the opencode CLI. This approach provides a self-contained repository while allowing us to pull updates from upstream.

## Directory Structure

```
Heimdall/
├── vendor/
│   └── opencode/        # Subtree copy of sst/opencode
├── src/                 # Heimdall-specific code
├── scripts/             # Maintenance scripts
│   ├── rebrand.js       # Rebranding automation
│   └── update-vendor.sh # Update script
└── bin/                 # Executable scripts
    └── heimdall         # Main CLI entry point
```

## Updating the Vendored Code

### Automatic Update

Run the update script to pull latest changes from opencode:

```bash
npm run update:vendor
# or
bash scripts/update-vendor.sh
```

This script will:
1. Fetch latest changes from opencode repository
2. Merge them into the vendor/opencode directory
3. Run the rebranding script
4. Install dependencies
5. Run tests (if available)

### Manual Update

If you need more control over the update process:

```bash
# Fetch latest from opencode
git fetch opencode dev

# Merge into subtree
git subtree pull --prefix=vendor/opencode opencode dev --squash

# Run rebranding
npm run rebrand

# Test the changes
npm test
```

## Rebranding Process

The rebranding script (`scripts/rebrand.js`) performs selective replacements:

### What Gets Rebranded
- User-facing strings in package.json
- CLI command names
- Documentation references
- Binary names

### What Stays Original
- Internal module references (to ease merging)
- Code structure
- API interfaces

### Running Rebranding

```bash
# Dry run (preview changes)
npm run rebrand:dry

# Apply rebranding
npm run rebrand
```

## Handling Merge Conflicts

When pulling upstream changes, conflicts may occur in rebranded files:

1. **Review conflicts carefully** - Check if the conflict is in rebranded code or original code
2. **Preserve rebranding** - Keep Heimdall branding in user-facing elements
3. **Accept upstream changes** - For internal code changes, prefer upstream version
4. **Re-run rebranding** - After resolving conflicts, run `npm run rebrand`

## Best Practices

1. **Regular Updates**: Pull upstream changes monthly or when critical updates are released
2. **Test Thoroughly**: Always test after updates, especially CLI commands
3. **Document Changes**: Keep a VENDOR_CHANGELOG.md with update history
4. **Minimal Modifications**: Keep changes to vendor code minimal to reduce conflicts
5. **Commit After Updates**: Always commit the vendor update as a separate commit

## Troubleshooting

### Binary Not Found
```bash
# Rebuild the vendor dependencies
cd vendor/opencode && bun install && bun run build
```

### Rebranding Issues
```bash
# Check what would be changed
npm run rebrand:dry

# Manually review and fix if needed
git diff vendor/opencode/
```

### Merge Conflicts
```bash
# Abort the subtree pull
git merge --abort

# Try pulling without squash for easier conflict resolution
git subtree pull --prefix=vendor/opencode opencode dev

# Or cherry-pick specific commits
git cherry-pick <commit-hash>
```

## Version Tracking

Track the vendored opencode version in:
- `vendor/opencode/package.json` - Original version
- `VENDOR_CHANGELOG.md` - Update history
- Git commit messages - Use format: "Update opencode vendor to vX.X.X"