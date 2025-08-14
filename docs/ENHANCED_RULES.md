# 🚀 Enhanced Rules System Documentation

## Overview

The Enhanced Rules System provides advanced control over instruction file loading with priority-based ordering, validation, and comprehensive logging.

## Features

- **Priority System**: Control load order with 0-100 priority values
- **Validation**: File size limits, required files, error handling
- **Flexible Paths**: Absolute, relative, glob patterns, home directory expansion
- **Detailed Logging**: Track what's loaded, errors, and performance
- **Backward Compatible**: Works with existing configurations

## Configuration

### Simple Format (Backward Compatible)

```json
{
  "rules": ["AGENTS.md", "PROJECT.md", "~/global-rules.md"]
}
```

### Advanced Format with Priority

```json
{
  "rules": [
    "AGENTS.md",  // Simple string, uses default priority 50
    {
      "path": "critical-rules.md",
      "priority": 100,     // Loaded last, highest override
      "required": true,    // Fails if not found
      "maxSize": 50000,    // Max 50KB
      "enabled": true      // Can be disabled
    },
    {
      "path": "~/global/*.md",  // Glob pattern with home expansion
      "priority": 10,           // Loaded first
      "required": false
    }
  ],
  "rulesConfig": {
    "failOnMissing": false,    // Don't fail on missing required files
    "logLevel": "info",        // Logging verbosity
    "maxTotalSize": 1000000,   // Max 1MB total
    "cacheDuration": 300       // Future: cache for 5 minutes
  }
}
```

## Priority System

### How It Works

1. **Range**: 0-100 (default: 50)
2. **Order**: Lower priority loads first
3. **Override**: Higher priority content appears later, can override earlier rules
4. **Sources**:
   - `rules` field: User-defined priority
   - `instructions` field: Priority 30
   - Default discovery: Priority 50

### Priority Guidelines

| Priority | Use Case | Example |
|----------|----------|---------|
| 0-20 | Base/foundation rules | Company standards |
| 21-40 | General guidelines | Team conventions |
| 41-60 | Project rules (default) | AGENTS.md |
| 61-80 | Feature-specific rules | Module guidelines |
| 81-100 | Critical overrides | Security requirements |

## Path Resolution

### Supported Formats

1. **Simple Filename**: `"AGENTS.md"`
   - Searches up from CWD to root

2. **Relative Path**: `"docs/rules.md"`
   - Relative to current directory

3. **Absolute Path**: `"/etc/heimdall/global.md"`
   - Direct file reference

4. **Home Directory**: `"~/rules/personal.md"`
   - Expands to user's home

5. **Glob Patterns**: `"docs/*.rules.md"`
   - Matches multiple files

6. **Project Directory**: `".heimdall/rules/*.md"`
   - Project-specific rules

## Rule Configuration Options

### Rule Object Properties

```typescript
{
  path: string,        // File path or pattern (required)
  priority?: number,   // 0-100, default 50
  required?: boolean,  // Fail if not found, default false
  maxSize?: number,    // Max file size in bytes
  enabled?: boolean    // Enable/disable rule, default true
}
```

### Global Configuration Options

```typescript
{
  failOnMissing?: boolean,  // Fail if any required file missing
  logLevel?: "debug" | "info" | "warn" | "error",
  maxTotalSize?: number,    // Max combined size (bytes)
  cacheDuration?: number    // Future: cache duration (seconds)
}
```

## Logging and Validation

### Log Levels

- **debug**: Full details including file contents info
- **info**: Summary of loaded files (default)
- **warn**: Only warnings and errors
- **error**: Only critical errors

### Log Output Example

```
INFO  loaded rule files {
  totalFiles: 5,
  totalSize: 15234,
  sources: {
    rules: 3,
    instructions: 1,
    default: 1
  },
  errors: 0
}
```

### Validation Features

1. **Size Limits**: Per-file and total size limits
2. **Required Files**: Fail or warn on missing
3. **Path Validation**: Prevents directory traversal
4. **Error Recovery**: Continue on non-critical errors

## File Attribution

Each loaded file includes metadata in the output:

```markdown
# filename.md [P90] (rules)
<!-- Path: /full/path/to/file.md | Size: 1234B | Modified: 2024-01-01T00:00:00.000Z -->

[File content here]
```

- `[P90]`: Priority indicator (shown if not default 50)
- `(rules)`: Source type (rules/instructions/default)

## Examples

### Example 1: Multi-Environment Setup

```json
{
  "rules": [
    {
      "path": "~/company-standards.md",
      "priority": 10,
      "required": true
    },
    {
      "path": ".heimdall/project-rules.md",
      "priority": 50
    },
    {
      "path": "feature/current-feature.md",
      "priority": 80,
      "enabled": true
    }
  ]
}
```

### Example 2: Development vs Production

```json
{
  "rules": [
    "AGENTS.md",
    {
      "path": "dev-rules.md",
      "enabled": "${NODE_ENV}" !== "production"
    },
    {
      "path": "/etc/heimdall/prod-rules.md",
      "enabled": "${NODE_ENV}" === "production",
      "required": true
    }
  ]
}
```

### Example 3: Size-Limited Documentation

```json
{
  "rules": [
    {
      "path": "docs/**/*.md",
      "maxSize": 10000,  // 10KB per file
      "priority": 30
    }
  ],
  "rulesConfig": {
    "maxTotalSize": 100000,  // 100KB total
    "logLevel": "debug"
  }
}
```

## Migration Guide

### From Default Discovery

**Before**: Files automatically discovered
```
AGENTS.md (in project root)
~/.config/heimdall/AGENTS.md
```

**After**: Explicit control (optional)
```json
{
  "rules": [
    "AGENTS.md",
    "~/.config/heimdall/AGENTS.md"
  ]
}
```

### From Instructions Field

**Before**:
```json
{
  "instructions": ["extra.md", "~/global.md"]
}
```

**After** (both work):
```json
{
  "rules": [
    { "path": "extra.md", "priority": 60 },
    { "path": "~/global.md", "priority": 40 }
  ],
  "instructions": ["legacy-support.md"]
}
```

## Troubleshooting

### Common Issues

1. **Required file not found**
   - Check path resolution
   - Verify file exists
   - Check permissions

2. **File exceeds size limit**
   - Increase `maxSize` for specific file
   - Increase `maxTotalSize` globally
   - Split large files

3. **Wrong load order**
   - Check priority values
   - Use debug logging to see order
   - Remember: lower priority loads first

4. **File not loading**
   - Check if `enabled: false`
   - Verify glob pattern
   - Check log level for errors

### Debug Commands

```bash
# Test with debug logging
./bin/heimdall --print-logs --log-level DEBUG 2>&1 | grep "system.rules"

# Test specific config
./bin/heimdall --config test/heimdall-rules-test.json --print-logs

# Check what files are found
find . -name "*.md" -type f | grep -E "(AGENTS|rules)"
```

## Best Practices

1. **Use Priorities Wisely**
   - Reserve 0-20 for foundations
   - Keep project rules at 40-60
   - Save 80-100 for critical overrides

2. **Organize by Purpose**
   - Global: `~/.config/heimdall/rules/`
   - Project: `.heimdall/rules/`
   - Feature: `feature/rules/`

3. **Set Size Limits**
   - Prevent accidental large file inclusion
   - Improve performance
   - Catch configuration errors early

4. **Use Required Sparingly**
   - Only for truly critical files
   - Provide good error messages
   - Consider fallbacks

5. **Enable Logging in Development**
   - Use `"logLevel": "debug"` during setup
   - Switch to `"info"` in production
   - Monitor for warnings

## Performance Considerations

- Files are loaded once per session
- Parallel file reading where possible
- Size limits prevent memory issues
- Future: caching support planned

## Security Notes

- Path traversal prevention built-in
- Size limits prevent DoS
- File permissions respected
- No arbitrary code execution

## API Reference

See the TypeScript definitions:
- `Config.RuleConfig` - Individual rule configuration
- `Config.RulesGlobalConfig` - Global rules settings
- `SystemPrompt.custom()` - Implementation details