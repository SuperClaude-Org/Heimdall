# Vendor Management Guide

## Overview

Heimdall uses Git subtree to vendor the opencode CLI, with a patch-based system for customizations. This approach keeps the vendor directory pristine while allowing modifications that survive updates.

## Architecture

```
heimdall/
├── vendor/opencode/     # Pristine opencode (never modify directly)
├── patches/             # Git patches for all customizations
├── scripts/
│   ├── patch-manager.js # Manage patches
│   └── update.sh        # Update workflow
├── bin/
│   └── heimdall         # Simple launcher
└── src/extensions/      # Future: new commands/features
```

## Working with Patches

### Apply Patches
```bash
npm run patch:apply
```

### Create a New Patch
1. Make changes to vendor files
2. Create patch from changes:
```bash
git diff vendor/ > patches/003-my-feature.patch
# Or use the patch manager
npm run patch:create "my-feature" "Description of changes"
```
3. Revert vendor changes
4. Apply patch to test

### List Patches
```bash
npm run patch:list
```

### Revert Patches
```bash
npm run patch:revert
```

## Updating Vendor

Run the update script:
```bash
npm run update
```

This will:
1. Revert all patches
2. Pull latest opencode via subtree
3. Reapply patches (reports conflicts)
4. Run basic tests

### Manual Update Process
```bash
# 1. Revert patches
npm run patch:revert

# 2. Update vendor
git subtree pull --prefix=vendor/opencode opencode dev --squash

# 3. Reapply patches
npm run patch:apply

# 4. Fix any conflicts and recreate patches if needed
```

## Best Practices

1. **Never modify vendor/ directly** - Always use patches
2. **Keep patches small** - Easier to maintain and resolve conflicts
3. **Document patches** - Add descriptions when creating
4. **Test after updates** - Ensure patches still work
5. **Commit patches separately** - Makes history cleaner

## Troubleshooting

### Patch Won't Apply
```bash
# Check what's wrong
git apply --check patches/001-example.patch

# If it fails, manually apply changes and recreate patch
# Edit the files as needed, then:
git diff vendor/ > patches/001-example-fixed.patch
```

### After Update Conflicts
1. Try to apply each patch individually
2. For failed patches, manually reapply changes
3. Create new patch from the changes
4. Replace old patch file

## Current Patches

Check `patches/` directory for active customizations:
- `002-heimdall-scriptname.patch` - Changes CLI name to "heimdall"

## Adding New Features

For completely new functionality (not modifications), add to `src/extensions/`:
- New commands in `src/extensions/commands/`
- New providers in `src/extensions/providers/`
- New tools in `src/extensions/tools/`

These don't need patches as they're separate from vendor code.