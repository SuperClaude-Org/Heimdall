# Pattern-Based Patching System

## Problem with Traditional Git Patches

Traditional git patches are fragile because they depend on:
- Exact line numbers
- Surrounding context that must match exactly
- File structure remaining unchanged

Example of a failing patch:
```diff
@@ -84,9 +85,9 @@ export namespace Server {
         openAPISpecs(app, {  // <-- If this moves to line 82, patch fails!
```

## Solution: Pattern-Based Replacements

Instead of line-based patches, we use search-and-replace patterns that are resilient to code changes.

### Advantages

1. **Line-number independent** - Patterns find content regardless of position
2. **Context-aware** - Can limit replacements to specific code contexts
3. **Upstream-resilient** - Survives most non-breaking upstream changes
4. **Readable configuration** - JSON format is easier to understand than diff
5. **Selective application** - Can apply/skip specific branding elements
6. **Better debugging** - Clear reporting of what was/wasn't changed

### How It Works

#### Configuration File: `branding-patterns.json`

```json
{
  "replacements": [
    {
      "name": "API Documentation",
      "files": ["vendor/opencode/packages/opencode/src/server/server.ts"],
      "patterns": [
        {
          "search": "title: \"opencode\"",
          "replace": "title: \"heimdall\"",
          "context": "openAPISpecs.*documentation"  // Optional context
        }
      ]
    }
  ]
}
```

#### Pattern Types

1. **Simple Replacement**
```json
{
  "search": "opencode",
  "replace": "heimdall"
}
```

2. **Global Replacement**
```json
{
  "search": "opencode",
  "replace": "heimdall",
  "global": true  // Replace all occurrences
}
```

3. **Context-Aware Replacement**
```json
{
  "search": "opencode",
  "replace": "heimdall",
  "context": "title|header|brand"  // Only replace in these contexts
}
```

4. **Multiline Replacement**
```json
{
  "search_multiline": "open := `\n█▀▀█ █▀▀█ █▀▀ █▀▀▄\n...",
  "replace_multiline": "heimdall := `\n██╗  ██╗███████╗██╗███╗\n..."
}
```

### Usage

```bash
# Apply branding
node scripts/apply-branding.js apply

# Validate patterns without applying
node scripts/apply-branding.js validate

# Revert changes (using backups)
node scripts/apply-branding.js revert
```

### Integration with Existing System

The pattern-based system can coexist with traditional patches:

```bash
# Traditional patches (for complex structural changes)
npm run patch:apply

# Pattern-based branding (for simple replacements)
node scripts/apply-branding.js apply
```

### When to Use Each Approach

| Use Traditional Patches | Use Pattern-Based |
|------------------------|-------------------|
| Complex code refactoring | Simple text replacements |
| Adding new files | Changing strings/names |
| Structural changes | Branding updates |
| Algorithm modifications | Configuration values |

### Example: Updating After Upstream Changes

With traditional patches:
```bash
# Often fails after upstream updates
npm run patch:apply
# ERROR: patch failed: line 84
# Manual intervention required...
```

With pattern-based system:
```bash
# Usually succeeds even after updates
node scripts/apply-branding.js apply
# ✓ Applied pattern: title: "opencode" → title: "heimdall"
# ✓ Updated server.ts (3 replacements)
```

### Migration Path

1. **Identify simple replacements** in existing patches
2. **Extract to patterns** in `branding-patterns.json`
3. **Keep complex changes** as traditional patches
4. **Test both systems** work together
5. **Document** which changes are where

### Best Practices

1. **Be specific** - Use context to avoid unintended replacements
2. **Test thoroughly** - Validate patterns before applying
3. **Keep backups** - Enable backup option in config
4. **Version control** - Commit pattern files
5. **Document patterns** - Use descriptive names

### Limitations

Pattern-based replacement is not suitable for:
- Adding new code blocks
- Removing code sections
- Complex refactoring
- Changes that depend on code logic

For these cases, continue using traditional git patches or direct code modification.

## Conclusion

The pattern-based system complements traditional patches by handling the most common and fragile changes (branding, naming) in a more robust way. This hybrid approach gives us the best of both worlds:
- **Reliability** for simple changes
- **Power** for complex modifications
- **Maintainability** as the project evolves