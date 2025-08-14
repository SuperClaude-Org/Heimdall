# Heimdall Layered Architecture

## Overview

Heimdall uses a sophisticated layered modification system that allows deep customization of opencode while maintaining clean vendor updates. This architecture provides multiple strategies for different types of modifications.

## Architecture Layers

```
┌─────────────────────────────────────┐
│         Heimdall CLI Entry          │
├─────────────────────────────────────┤
│     Layer 4: Complete Overrides     │  ← Full file replacements
├─────────────────────────────────────┤
│     Layer 3: Extensions & New       │  ← New features
├─────────────────────────────────────┤
│     Layer 2: Runtime Patches        │  ← Dynamic modifications
├─────────────────────────────────────┤
│     Layer 1: Git Patches            │  ← Surgical file changes
├─────────────────────────────────────┤
│     Layer 0: Pristine Vendor        │  ← Never modified
└─────────────────────────────────────┘
```

## Directory Structure

```
heimdall/
├── vendor/opencode/          # Layer 0: NEVER MODIFIED
│   └── [pristine opencode source]
│
├── patches/                  # Layer 1: Git patches
│   ├── 001-heimdall-branding.patch
│   └── 002-custom-feature.patch
│
├── src/
│   ├── core/                # Core systems
│   │   ├── loader.ts       # Module resolution
│   │   ├── patcher.ts      # Runtime patching
│   │   └── injector.ts     # Dependency injection
│   │
│   ├── extensions/          # Layer 3: New features
│   │   ├── commands/       # Custom commands
│   │   ├── providers/      # AI providers
│   │   └── tools/         # Additional tools
│   │
│   └── overrides/          # Layer 4: Complete replacements
│       └── opencode/       # Mirrors vendor structure
│           └── packages/
│               └── opencode/
│                   └── src/
│                       └── index.ts  # Overridden entry
│
└── scripts/
    ├── patch-manager.js    # Manage git patches
    └── update-heimdall.sh  # Update workflow
```

## Layer Details

### Layer 0: Pristine Vendor (Base)
- **Location**: `vendor/opencode/`
- **Modification**: NEVER - Always clean
- **Purpose**: Clean upstream source for updates
- **Update**: `git subtree pull`

### Layer 1: Git Patches
- **Location**: `patches/`
- **Tool**: `scripts/patch-manager.js`
- **Use Case**: Small, surgical modifications
- **Survives Updates**: With manual conflict resolution

Example:
```bash
# Create a patch from current changes
node scripts/patch-manager.js create "custom-feature" "Add custom feature X"

# Apply patches
node scripts/patch-manager.js apply

# Verify patches
node scripts/patch-manager.js verify
```

### Layer 2: Runtime Patches
- **Location**: `src/core/patcher.ts`
- **Use Case**: Dynamic behavior modification
- **Survives Updates**: Yes, automatically

Example:
```typescript
patcher.register({
  target: 'vendor/opencode/packages/opencode/src/cli.ts',
  method: 'displayBanner',
  type: 'wrap',
  patch: (original, self, args) => {
    console.log('Heimdall Banner');
    // Don't call original
  }
});
```

### Layer 3: Extensions
- **Location**: `src/extensions/`
- **Use Case**: Completely new functionality
- **Survives Updates**: Yes, always

Example:
```typescript
// src/extensions/commands/custom.ts
export class CustomCommand {
  static command = 'custom';
  static handler() {
    // New functionality
  }
}
```

### Layer 4: Complete Overrides
- **Location**: `src/overrides/`
- **Use Case**: Complete file replacement
- **Survives Updates**: Yes, but may need updates

Example:
```
src/overrides/opencode/packages/opencode/src/index.ts
# Completely replaces the vendor file
```

## Modification Decision Tree

```
Need to modify opencode?
│
├─ Is it new functionality?
│  └─ YES → Use Extensions (Layer 3)
│
├─ Is it a small change (<50 lines)?
│  └─ YES → Use Git Patches (Layer 1)
│
├─ Is it runtime behavior?
│  └─ YES → Use Runtime Patches (Layer 2)
│
├─ Need to replace entire file?
│  └─ YES → Use Override (Layer 4)
│
└─ Complex multi-file changes?
   └─ Consider a combination approach
```

## Update Workflow

### Automatic Update Process

```bash
# Run the update script
./scripts/update-heimdall.sh
```

This script:
1. Reverts patches temporarily
2. Pulls latest opencode via subtree
3. Reapplies patches (reports conflicts)
4. Verifies overrides compatibility
5. Runs tests

### Manual Update Process

```bash
# 1. Revert patches
node scripts/patch-manager.js revert

# 2. Update vendor
git subtree pull --prefix=vendor/opencode opencode dev --squash

# 3. Reapply patches
node scripts/patch-manager.js apply

# 4. Test
bun test

# 5. Update overrides if needed
# Compare override files with vendor equivalents
```

## Best Practices

### 1. Choose the Right Layer
- **Extensions** for new features (preferred)
- **Patches** for small changes
- **Runtime** for behavior modifications
- **Overrides** as last resort

### 2. Document Everything
```javascript
// In patches/README.md
001-heimdall-branding.patch
  Purpose: Rebrand CLI to Heimdall
  Files: 6 files
  Conflicts: May conflict with CLI refactors

// In src/overrides/README.md
index.ts
  Purpose: Custom entry point with Heimdall branding
  Vendor: vendor/opencode/packages/opencode/src/index.ts
  Last sync: 2024-08-14
```

### 3. Test After Updates
```typescript
// tests/layers.test.ts
describe('Layered Architecture', () => {
  test('patches apply cleanly', () => {
    // Test patch application
  });
  
  test('overrides load correctly', () => {
    // Test override resolution
  });
  
  test('extensions initialize', () => {
    // Test extension loading
  });
});
```

### 4. Minimize Vendor Modifications
- Never modify `vendor/` directly
- Use the minimal intervention needed
- Prefer composition over modification

## Troubleshooting

### Patch Conflicts
```bash
# See which patches fail
node scripts/patch-manager.js verify

# Manually fix and recreate
git diff vendor/ > patches/001-fixed.patch
```

### Override Out of Sync
```bash
# Compare override with vendor
diff src/overrides/opencode/packages/opencode/src/index.ts \
     vendor/opencode/packages/opencode/src/index.ts

# Update override from vendor
cp vendor/opencode/packages/opencode/src/index.ts \
   src/overrides/opencode/packages/opencode/src/index.ts
# Then reapply customizations
```

### Extension Not Loading
```bash
# Check extension discovery
bun run src/extensions/index.ts

# Verify extension format
# Must export default with name, type, and init
```

## Examples

### Example 1: Add Custom Command

```typescript
// src/extensions/commands/analyze.ts
import { Extension } from '../index';

export class AnalyzeCommand {
  static command = 'analyze <file>';
  static describe = 'Analyze code file';
  
  static async handler(argv) {
    console.log(`Analyzing ${argv.file}`);
    // Custom logic
  }
}

export default {
  name: 'analyze',
  type: 'command',
  async init() {
    // Register with CLI
  }
} as Extension;
```

### Example 2: Modify Existing Behavior

```typescript
// src/core/patches/custom-run.ts
import { patcher } from '../patcher';

patcher.register({
  target: 'vendor/opencode/packages/opencode/src/cli/cmd/run.ts',
  method: 'handler',
  type: 'wrap',
  patch: (original, self, args) => {
    console.log('[Heimdall] Intercepting run command');
    // Pre-processing
    const result = original.apply(self, args);
    // Post-processing
    return result;
  }
});
```

### Example 3: Override for Deep Changes

```typescript
// src/overrides/opencode/packages/opencode/src/cli/ui.ts
// Complete replacement of UI module
export class UI {
  static banner() {
    console.log('Heimdall Custom Banner');
  }
  // ... rest of UI implementation
}
```

## Migration from Direct Modification

If you previously modified vendor files directly:

1. **Save your changes**:
   ```bash
   git diff vendor/ > my-changes.patch
   ```

2. **Revert vendor**:
   ```bash
   git checkout vendor/
   ```

3. **Apply as patches**:
   ```bash
   cp my-changes.patch patches/001-migration.patch
   node scripts/patch-manager.js apply
   ```

4. **Or create overrides**:
   ```bash
   # For heavily modified files
   cp modified-file.ts src/overrides/path/to/file.ts
   ```

## Conclusion

The layered architecture provides maximum flexibility while maintaining clean separation between vendor code and customizations. This ensures:

- ✅ **Clean updates** from upstream
- ✅ **Clear customization boundaries**
- ✅ **Multiple modification strategies**
- ✅ **Survivable customizations**
- ✅ **Maintainable codebase**

Choose the appropriate layer for each modification, and your Heimdall customizations will survive and thrive through updates.