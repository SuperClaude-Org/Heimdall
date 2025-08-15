# Heimdall Configuration Schema Documentation

## Overview

The Heimdall configuration uses JSON format with full schema validation. The configuration file can be named `heimdall.json` or `heimdall.jsonc` (with comments).

## Schema Files

- **`config.schema.json`** - Complete JSON Schema for validation
- **`heimdall.example.json`** - Example configuration with all features
- **Schema URL**: `https://heimdall.ai/config.json`

## Configuration Locations

Heimdall searches for configuration in this order:
1. Project directory (up to git root): `heimdall.json`
2. Global config: `~/.config/heimdall/heimdall.json`
3. Custom path via `HEIMDALL_CONFIG` environment variable

## New Features in Heimdall

### 1. Enhanced Rules System

The `rules` field provides advanced control over instruction file loading:

```json
{
  "rules": [
    "AGENTS.md",  // Simple string format
    {
      "path": "~/company-standards.md",
      "priority": 10,      // 0-100, higher loads later
      "required": false,   // Don't fail if missing
      "maxSize": 50000,    // Max 50KB
      "enabled": true      // Can be toggled
    }
  ],
  "rulesConfig": {
    "failOnMissing": false,
    "logLevel": "info",
    "maxTotalSize": 1000000
  }
}
```

### 2. Priority System

- **Range**: 0-100 (default: 50)
- **Lower priority**: Loads first (foundation)
- **Higher priority**: Loads later (can override)

Priority Guidelines:
- 0-20: Base/foundation rules
- 21-40: General guidelines
- 41-60: Project rules (default)
- 61-80: Feature-specific rules
- 81-100: Critical overrides

## Core Configuration Fields

### Model Configuration

```json
{
  "model": "anthropic/claude-3-5-sonnet-latest",
  "small_model": "anthropic/claude-3-haiku",
  "username": "Alice"
}
```

### Agent Configuration

Define custom agents with specific behaviors:

```json
{
  "agent": {
    "build": {
      "description": "Full development mode",
      "temperature": 0.7,
      "model": "anthropic/claude-3-5-sonnet",
      "tools": {
        "write": true,
        "edit": true,
        "bash": true,
        "read": true
      },
      "permission": {
        "edit": "ask",
        "bash": "allow",
        "webfetch": "allow"
      }
    }
  }
}
```

### MCP Servers

Configure Model Context Protocol servers:

```json
{
  "mcp": {
    "morphllm": {
      "type": "local",
      "command": ["npx", "@morph-llm/morph-fast-apply"],
      "environment": {
        "MORPH_API_KEY": "key"
      },
      "enabled": true
    },
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/sse",
      "enabled": true
    }
  }
}
```

### Keybindings

Customize keyboard shortcuts:

```json
{
  "keybinds": {
    "leader": "ctrl+x",
    "switch_agent": "tab",
    "session_new": "<leader>n",
    "app_exit": "ctrl+c,<leader>q"
  }
}
```

### Formatters

Configure code formatters:

```json
{
  "formatter": {
    "prettier": {
      "command": ["npx", "prettier", "--write", "$FILE"],
      "extensions": [".js", ".ts", ".json", ".md"],
      "disabled": false
    }
  }
}
```

### Language Servers

Configure LSP servers:

```json
{
  "lsp": {
    "typescript-language-server": {
      "command": ["typescript-language-server", "--stdio"],
      "extensions": [".js", ".ts", ".tsx"],
      "disabled": false
    }
  }
}
```

### Permissions

Control tool permissions:

```json
{
  "permission": {
    "edit": "ask",      // ask, allow, deny
    "bash": {
      "rm": "deny",     // Specific command
      "*": "ask"        // Default for others
    },
    "webfetch": "allow"
  }
}
```

### Experimental Features

```json
{
  "experimental": {
    "hook": {
      "file_edited": {
        ".py": [
          {
            "command": ["ruff", "check", "$FILE"]
          }
        ]
      },
      "session_completed": [
        {
          "command": ["notify-send", "Session complete"]
        }
      ]
    }
  }
}
```

## Schema Validation

### Using VS Code

Add to your `heimdall.json`:
```json
{
  "$schema": "./config.schema.json"
}
```

Or configure in VS Code settings:
```json
{
  "json.schemas": [
    {
      "fileMatch": ["heimdall.json", "heimdall.jsonc"],
      "url": "./config.schema.json"
    }
  ]
}
```

### Command Line Validation

```bash
# Using ajv-cli
npm install -g ajv-cli
ajv validate -s config.schema.json -d heimdall.json

# Using Python jsonschema
pip install jsonschema
python -m jsonschema -i heimdall.json config.schema.json
```

## Migration from OpenCode

### Configuration Changes

| OpenCode | Heimdall | Notes |
|----------|----------|-------|
| `opencode.json` | `heimdall.json` | Filename change |
| `~/.config/opencode/` | `~/.config/heimdall/` | Directory change |
| `.opencode/` | `.heimdall/` | Project directory |
| No rules field | `rules` field | New feature |
| `instructions` only | `rules` + `instructions` | Enhanced system |

### New Fields in Heimdall

1. **`rules`**: Advanced rule file configuration
2. **`rulesConfig`**: Global rule loading settings
3. Both fields are optional and backward compatible

## Examples

### Minimal Configuration

```json
{
  "$schema": "https://heimdall.ai/config.json",
  "model": "anthropic/claude-3-5-sonnet-latest"
}
```

### Development Setup

```json
{
  "$schema": "https://heimdall.ai/config.json",
  "rules": [
    "AGENTS.md",
    {
      "path": "~/dev-standards.md",
      "priority": 20
    }
  ],
  "model": "anthropic/claude-3-5-sonnet-latest",
  "agent": {
    "build": {
      "temperature": 0.7,
      "tools": {
        "write": true,
        "edit": true,
        "bash": true
      }
    }
  }
}
```

### Team Configuration

```json
{
  "$schema": "https://heimdall.ai/config.json",
  "rules": [
    {
      "path": "/shared/team-rules.md",
      "priority": 10,
      "required": true
    },
    {
      "path": "project-rules.md",
      "priority": 50
    }
  ],
  "rulesConfig": {
    "failOnMissing": true,
    "logLevel": "warn"
  },
  "username": "TeamMember",
  "permission": {
    "edit": "ask",
    "bash": {
      "rm": "deny",
      "*": "ask"
    }
  }
}
```

## Troubleshooting

### Schema Validation Errors

1. **Unknown property**: Check spelling and schema version
2. **Type mismatch**: Verify data types match schema
3. **Required field missing**: Add required fields
4. **Enum value invalid**: Use allowed values only

### Rules Not Loading

1. Check file paths are correct
2. Verify file permissions
3. Check `enabled` field is true
4. Review log level settings
5. Check size limits

### Priority Issues

1. Use debug logging to see load order
2. Remember: lower priority loads first
3. Check for conflicting rules
4. Verify priority values are 0-100

## Best Practices

1. **Use Schema Validation**: Always include `$schema` field
2. **Start Simple**: Begin with minimal config, add features as needed
3. **Document Rules**: Use clear filenames and paths
4. **Test Changes**: Validate config after changes
5. **Version Control**: Track config changes in git
6. **Team Standards**: Share base rules via low priority
7. **Local Overrides**: Use high priority for local customization

## Related Documentation

- [Enhanced Rules System](./ENHANCED_RULES.md)
- [AGENTS Discovery](./AGENTS_DISCOVERY.md)
- [Logging Guide](./LOGGING.md)
- [Testing Guide](../TESTING.md)