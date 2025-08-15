# Heimdall Patching System

## Overview

Heimdall uses a sophisticated Zig-based intelligent patching system with fuzzy matching, automatic fallback strategies, and pattern-based replacements. This hybrid approach ensures maximum reliability when maintaining customizations on top of the upstream opencode project.

## Architecture

### Core Components

1. **Zig Patcher** (`/build/src/patcher.zig`)
   - Intelligent fuzzy matching
   - Multiple fallback strategies
   - Context-aware patching
   - Automatic conflict resolution

2. **Patch Format** (`/build/patches/*.hpatch.json`)
   - JSON-based patch definitions
   - Pattern matching rules
   - Transformation specifications
   - Metadata and versioning

3. **Build Integration** (`/build/src/build.zig`)
   - Automated patch application
   - Verification and rollback
   - Progress reporting

## Patch Types

### 1. Pattern-Based Replacements
Best for simple text substitutions and branding changes.

```json
{
  "name": "heimdall-branding",
  "version": "2.0.0",
  "patterns": [
    {
      "search": "opencode",
      "replace": "heimdall",
      "files": ["**/*.ts", "**/*.js"],
      "context": "title|brand|name"
    }
  ]
}
```

**Advantages:**
- Line-number independent
- Survives upstream changes
- Selective application
- Clear debugging

### 2. Structural Patches
For complex code modifications and refactoring.

```json
{
  "name": "enhanced-features",
  "version": "2.0.0",
  "patches": [
    {
      "file": "server.ts",
      "hunks": [
        {
          "context": "function initialize",
          "additions": ["new feature code"],
          "removals": ["old code"]
        }
      ]
    }
  ]
}
```

### 3. Fuzzy Patches
Intelligent matching when exact patterns fail.

```json
{
  "name": "ascii-art",
  "version": "2.0.0",
  "fuzzy": true,
  "threshold": 0.8,
  "patterns": [
    {
      "search_multiline": "ASCII art pattern",
      "replace_multiline": "New ASCII art",
      "similarity": 0.8
    }
  ]
}
```

## Matching Strategies

The patcher employs multiple strategies in order:

1. **Exact Match** - Direct string/pattern matching
2. **Fuzzy Match** - Similarity-based matching (configurable threshold)
3. **Context Match** - Uses surrounding code as anchor points
4. **Semantic Match** - AST-based matching for code structure
5. **Manual Fallback** - Prompts for manual resolution

## Usage

### Command Line Interface

```bash
# Apply all patches
./build/bin/heimdall-patcher apply

# Apply specific patch
./build/bin/heimdall-patcher apply heimdall-branding

# Verify patches
./build/bin/heimdall-patcher verify

# Dry run
./build/bin/heimdall-patcher apply --dry-run

# Verbose output
./build/bin/heimdall-patcher apply --verbose
```

### Build System Integration

```bash
# Full build pipeline
./build/bin/heimdall-build

# Includes:
# 1. Update vendor
# 2. Apply patches
# 3. Verify branding
# 4. Build binaries
```

## Creating Patches

### Interactive Creation
```bash
./build/bin/heimdall-patcher create my-patch
```

### Manual Creation
Create a `.hpatch.json` file in `/build/patches/`:

```json
{
  "name": "my-custom-patch",
  "version": "1.0.0",
  "description": "Description of changes",
  "author": "Your Name",
  "patterns": [
    {
      "files": ["target/file.ts"],
      "search": "original text",
      "replace": "new text"
    }
  ]
}
```

## Best Practices

### When to Use Each Approach

| Use Pattern-Based | Use Structural | Use Fuzzy |
|------------------|----------------|-----------|
| Branding changes | New features | ASCII art |
| String replacements | Code refactoring | Formatted text |
| Configuration values | Algorithm changes | Comments |
| Simple UI text | Import additions | Documentation |

### Patch Organization

1. **Naming Convention**
   - `feature-name.hpatch.json`
   - Use descriptive names
   - Include version numbers

2. **Granularity**
   - One feature per patch file
   - Separate branding from functionality
   - Group related changes

3. **Documentation**
   - Include clear descriptions
   - Document dependencies
   - Note upstream compatibility

### Testing Patches

1. **Always dry-run first**
   ```bash
   ./build/bin/heimdall-patcher apply --dry-run
   ```

2. **Verify after application**
   ```bash
   ./build/bin/heimdall-patcher verify
   ```

3. **Test build**
   ```bash
   ./build/bin/heimdall-build --dry-run
   ```

## Troubleshooting

### Common Issues

1. **Patch Fails to Apply**
   - Check if upstream changed significantly
   - Try increasing fuzzy threshold
   - Review context patterns

2. **Multiple Matches**
   - Make patterns more specific
   - Add context restrictions
   - Use file-specific patterns

3. **Performance Issues**
   - Reduce fuzzy matching threshold
   - Limit file scope
   - Use exact matches where possible

### Debug Mode

```bash
# Enable detailed logging
./build/bin/heimdall-patcher apply --verbose --debug

# Outputs:
# - Match attempts
# - Strategy fallbacks
# - Similarity scores
# - Context analysis
```

## Migration from Git Patches

### Converting Old Patches

1. **Identify simple replacements**
   ```bash
   grep -E "^[-+]" old-patch.patch | grep -v "^[-+]{3}"
   ```

2. **Extract to patterns**
   - Text changes → Pattern-based
   - Code changes → Structural
   - Mixed → Split into multiple patches

3. **Test conversion**
   ```bash
   ./build/bin/heimdall-patcher verify new-patch
   ```

### Gradual Migration

1. Start with branding patches (highest failure rate)
2. Move to configuration patches
3. Keep complex patches as-is initially
4. Convert as needed when they fail

## Performance Characteristics

- **Exact Matching**: O(n) - Linear search
- **Fuzzy Matching**: O(n*m) - Edit distance calculation
- **Context Matching**: O(n*log(n)) - Pattern analysis
- **Typical patch set**: < 1 second application time

## Future Enhancements

1. **AST-Based Patching**
   - Language-aware modifications
   - Semantic understanding
   - Refactoring support

2. **Conflict Resolution UI**
   - Interactive merge tool
   - Visual diff display
   - Suggestion system

3. **Patch Composition**
   - Dependency management
   - Conditional application
   - Feature flags

## Conclusion

The Heimdall patching system provides a robust, maintainable approach to customizing upstream code. By combining multiple matching strategies with intelligent fallbacks, it achieves high reliability while remaining simple to use and understand.

For more details on specific components:
- Build System: See [BUILD_SYSTEM.md](BUILD_SYSTEM.md)
- Vendor Management: See [VENDOR_MANAGEMENT.md](VENDOR_MANAGEMENT.md)