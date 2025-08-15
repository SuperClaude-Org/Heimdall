# Heimdall Build System

## Overview

The Heimdall build system is a sophisticated Zig-based pipeline that manages vendor updates, patch application, verification, and compilation in a unified workflow.

## Architecture

### Core Components

- **Build Orchestrator** (`build/src/build.zig`) - Manages the 6-stage pipeline
- **Patcher** (`build/src/patcher.zig`) - Intelligent patch application
- **Verifier** (`build/src/verifier.zig`) - Branding verification
- **Transformer** (`build/src/transformer.zig`) - Code transformations
- **Reporter** (`build/src/reporter.zig`) - Progress and error reporting

## Build Pipeline

### Stage 1: Update
Updates the vendor directory from upstream repository.

```bash
# Manual update
git -C vendor/opencode pull origin main
```

### Stage 2: Prepare
Creates a clean build directory by copying vendor code.

- Removes existing `.build/` directory
- Creates fresh `.build/heimdall/`
- Copies `vendor/opencode/` → `.build/heimdall/`

### Stage 3: Transform
Applies patches and transformations to the build directory.

- Loads patches from `build/patches/*.hpatch.json`
- Applies each patch with fuzzy matching
- Runs additional transformations

### Stage 4: Verify
Checks that all branding and customizations are complete.

- Scans for remaining "opencode" references
- Validates ASCII art changes
- Reports completeness score

### Stage 5: Build
Compiles the Heimdall binaries.

```bash
cd .build/heimdall
bun install
bun run build
```

### Stage 6: Finalize
Packages artifacts and performs cleanup.

- Copies binaries to `dist/`
- Generates build report
- Optionally cleans build directory

## Usage

### Basic Commands

```bash
# Full build
./build/bin/heimdall-build

# Dry run (preview changes)
./build/bin/heimdall-build --dry-run

# Verbose output
./build/bin/heimdall-build --verbose

# Force through errors
./build/bin/heimdall-build --force

# Auto-fix issues
./build/bin/heimdall-build --auto-fix
```

### Configuration

The build system uses `build/config/build.yaml`:

```yaml
source:
  repository: https://github.com/opencode/opencode.git
  branch: main
  path: vendor/opencode

build:
  temp_dir: .build/heimdall
  output_dir: dist
  clean_after_build: true

patches:
  directory: build/patches
  auto_fix: false
  backup: true
```

## Patcher System

### Patch Format

Patches use the `.hpatch.json` format:

```json
{
  "name": "heimdall-branding",
  "version": "2.0.0",
  "description": "Apply Heimdall branding",
  "patterns": [
    {
      "files": ["**/*.ts"],
      "search": "opencode",
      "replace": "heimdall",
      "context": "title|brand"
    }
  ]
}
```

### Matching Strategies

1. **Exact Match** - Direct string matching
2. **Fuzzy Match** - Similarity-based (80% threshold)
3. **Context Match** - Uses surrounding code
4. **Manual Fallback** - User intervention

### Creating Patches

```bash
# Interactive creation
./build/bin/heimdall-patcher create my-patch

# Convert from git patch
./build/bin/heimdall-patcher convert old.patch

# Verify patch
./build/bin/heimdall-patcher verify my-patch
```

## Development

### Building the Build System

```bash
cd build
zig build -Doptimize=ReleaseFast
```

### Testing

```bash
# Run all tests
zig build test

# Test specific component
zig test src/patcher.zig
```

### Debugging

```bash
# Enable debug output
export HEIMDALL_DEBUG=1
./build/bin/heimdall-build --verbose

# Check intermediate state
ls -la .build/heimdall/
```

## Troubleshooting

### Common Issues

#### Patch Application Fails
- Check if upstream changed significantly
- Review patch context patterns
- Try `--auto-fix` flag

#### Build Hangs
- Check for infinite loops in patches
- Verify network connectivity for git operations
- Review verbose output

#### Verification Fails
- Run verifier separately: `heimdall-patcher verify`
- Check for missed branding locations
- Review verification rules

### Error Codes

- `UpdateFailed` - Git operations failed
- `PrepareFailed` - Build directory setup failed
- `TransformFailed` - Patch application failed
- `VerificationFailed` - Branding incomplete
- `CompilationFailed` - Build process failed

## Advanced Features

### Custom Transformations

Add transformations in `build/src/transformer.zig`:

```zig
pub fn applyCustomTransform(path: []const u8) !void {
    // Custom transformation logic
}
```

### Verification Rules

Define rules in `build/config/branding.yaml`:

```yaml
rules:
  - pattern: "opencode"
    forbidden: true
    exceptions: ["vendor/"]
  - pattern: "╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦"
    required: true
    files: ["README.md"]
```

### Build Hooks

Add hooks in the build pipeline:

```zig
// Pre-build hook
try self.runHook("pre-build");

// Post-build hook
try self.runHook("post-build");
```

## Performance

- **Typical build time**: 10-30 seconds
- **Patch application**: < 1 second per patch
- **Verification**: 2-5 seconds
- **Memory usage**: ~50MB

## Best Practices

1. **Always dry-run first** before actual builds
2. **Keep patches small** and focused
3. **Document patches** with clear descriptions
4. **Test patches** after upstream updates
5. **Use version control** for patch files

## Future Enhancements

- [ ] Parallel patch application
- [ ] Incremental builds
- [ ] Cache management
- [ ] Web UI for build monitoring
- [ ] Automated upstream tracking