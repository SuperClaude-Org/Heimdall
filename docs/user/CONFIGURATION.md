# Heimdall Configuration Guide

## Overview

Heimdall uses JSON format for configuration with support for both `heimdall.json` and `heimdall.jsonc` (with comments). The configuration system is backward compatible with opencode while adding enhanced features.

## Configuration Locations

Heimdall searches for configuration in this order:
1. Current directory and parent directories (up to git root): `heimdall.json`
2. Project-specific: `.heimdall/heimdall.json`
3. Global config: `~/.config/heimdall/heimdall.json`
4. Legacy support: `opencode.json` (if heimdall.json not found)
5. Custom path via `HEIMDALL_CONFIG` environment variable

## Configuration Structure

### Basic Configuration

```json
{
  "$schema": "https://heimdall.ai/config.json",
  "model": "anthropic/claude-3-5-sonnet-latest",
  "small_model": "anthropic/claude-3-haiku",
  "username": "Developer",
  "theme": "dark"
}
```

### Enhanced Rules System

The `rules` field provides advanced control over instruction file loading:

```json
{
  "rules": [
    "AGENTS.md",  // Simple string format
    {
      "path": "~/company-standards.md",
      "priority": 10,      // 0-100, lower loads first
      "required": false,   // Don't fail if missing
      "enabled": true,     // Can be toggled
      "maxSize": 50000     // Max file size in bytes
    },
    {
      "path": ".heimdall/project-rules.md",
      "priority": 50,
      "maxSize": 50000
    },
    {
      "path": "docs/**/*.rules.md",  // Glob pattern support
      "priority": 30,
      "enabled": true
    },
    {
      "path": "/etc/heimdall/critical-security.md",
      "priority": 95,
      "required": true,
      "maxSize": 10000
    }
  ],
  "rulesConfig": {
    "failOnMissing": false,
    "logLevel": "info",
    "maxTotalSize": 1000000,
    "cacheDuration": 300
  }
}
```

### Priority System Guidelines

| Priority | Use Case | Example |
|----------|----------|---------|
| 0-20 | Base/foundation rules | Company standards, team conventions |
| 21-40 | General guidelines | Coding standards, best practices |
| 41-60 | Project rules (default) | AGENTS.md, project-specific rules |
| 61-80 | Feature-specific rules | Module guidelines, current work |
| 81-100 | Critical overrides | Security requirements, compliance |

## Agent Configuration

Define custom agents with specific behaviors and tool permissions:

```json
{
  "agent": {
    "build": {
      "description": "Full development mode",
      "temperature": 0.7,
      "tools": {
        "write": true,
        "edit": true,
        "bash": true,
        "read": true
      }
    },
    "plan": {
      "description": "Planning without modifications",
      "temperature": 0.3,
      "tools": {
        "write": false,
        "edit": false,
        "bash": false,
        "read": true
      }
    },
    "review": {
      "description": "Code review mode",
      "model": "anthropic/claude-3-opus",
      "temperature": 0.1,
      "prompt": "Focus on best practices, security, and performance.",
      "tools": {
        "write": false,
        "edit": false,
        "read": true
      }
    },
    "debug": {
      "description": "Debugging mode",
      "temperature": 0.4,
      "prompt": "Focus on root causes and fixes.",
      "tools": {
        "write": true,
        "edit": true,
        "bash": true,
        "read": true
      }
    }
  }
}
```

## MCP (Model Context Protocol) Servers

Configure MCP servers for enhanced tool capabilities:

```json
{
  "mcp": {
    "morphllm-fast-apply": {
      "type": "local",
      "command": ["npx", "@morph-llm/morph-fast-apply", "/home/user/"],
      "environment": {
        "MORPH_API_KEY": "your-api-key",
        "ALL_TOOLS": "true"
      },
      "enabled": true
    },
    "serena": {
      "type": "local",
      "command": ["uvx", "--from", "git+https://github.com/oraios/serena", "serena", "start-mcp-server"],
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

## Keybindings

Customize keyboard shortcuts for the TUI:

```json
{
  "keybinds": {
    "leader": "ctrl+x",
    "switch_agent": "tab",
    "switch_agent_reverse": "shift+tab",
    "session_new": "<leader>n",
    "session_list": "<leader>l",
    "model_list": "<leader>m",
    "file_list": "<leader>f",
    "app_exit": "ctrl+c,<leader>q"
  }
}
```

## Formatters and Language Servers

### Code Formatters

```json
{
  "formatter": {
    "prettier": {
      "command": ["npx", "prettier", "--write", "$FILE"],
      "extensions": [".js", ".jsx", ".ts", ".tsx", ".json", ".md"]
    },
    "ruff": {
      "command": ["ruff", "format", "$FILE"],
      "extensions": [".py", ".pyi"]
    }
  }
}
```

### Language Server Protocol (LSP)

```json
{
  "lsp": {
    "typescript-language-server": {
      "command": ["typescript-language-server", "--stdio"],
      "extensions": [".js", ".jsx", ".ts", ".tsx"]
    },
    "pyright": {
      "command": ["pyright-langserver", "--stdio"],
      "extensions": [".py", ".pyi"]
    }
  }
}
```

## Permissions

Control tool permissions with granular settings:

```json
{
  "permission": {
    "edit": "ask",      // ask, allow, deny
    "bash": {
      "rm": "deny",     // Specific command denial
      "*": "ask"        // Default for other commands
    },
    "webfetch": "allow"
  }
}
```

## Experimental Features

### Hooks

Execute commands on specific events:

```json
{
  "experimental": {
    "hook": {
      "file_edited": {
        ".py": [
          {
            "command": ["ruff", "check", "$FILE"],
            "environment": {}
          }
        ]
      },
      "session_completed": [
        {
          "command": ["notify-send", "Heimdall", "Session completed"],
          "environment": {}
        }
      ]
    }
  }
}
```

## Other Settings

```json
{
  "instructions": ["legacy-instructions.md"],  // Legacy instruction files
  "share": "manual",                           // Sharing mode
  "autoupdate": true,                          // Auto-update enabled
  "snapshot": true,                            // Session snapshots
  "disabled_providers": []                     // Disabled AI providers
}
```

## Complete Example

Here's a comprehensive configuration example:

```json
{
  "$schema": "https://heimdall.ai/config.json",
  "rules": [
    "AGENTS.md",
    {
      "path": "~/company-standards.md",
      "priority": 10,
      "required": false,
      "enabled": true
    },
    {
      "path": ".heimdall/project-rules.md",
      "priority": 50,
      "maxSize": 50000
    }
  ],
  "rulesConfig": {
    "failOnMissing": false,
    "logLevel": "info",
    "maxTotalSize": 1000000,
    "cacheDuration": 300
  },
  "model": "anthropic/claude-3-5-sonnet-latest",
  "small_model": "anthropic/claude-3-haiku",
  "username": "Developer",
  "theme": "dark",
  "agent": {
    "build": {
      "description": "Full development mode",
      "temperature": 0.7,
      "tools": {
        "write": true,
        "edit": true,
        "bash": true,
        "read": true
      }
    }
  },
  "mcp": {
    "morphllm-fast-apply": {
      "type": "local",
      "command": ["npx", "@morph-llm/morph-fast-apply", "/home/user/"],
      "environment": {
        "MORPH_API_KEY": "your-api-key",
        "ALL_TOOLS": "true"
      },
      "enabled": true
    }
  },
  "keybinds": {
    "leader": "ctrl+x",
    "switch_agent": "tab"
  },
  "formatter": {
    "prettier": {
      "command": ["npx", "prettier", "--write", "$FILE"],
      "extensions": [".js", ".jsx", ".ts", ".tsx", ".json", ".md"]
    }
  },
  "permission": {
    "edit": "ask",
    "bash": {
      "rm": "deny",
      "*": "ask"
    },
    "webfetch": "allow"
  },
  "experimental": {
    "hook": {
      "session_completed": [
        {
          "command": ["notify-send", "Heimdall", "Session completed"]
        }
      ]
    }
  }
}
```

## Migration from OpenCode

### Configuration Changes

| OpenCode | Heimdall | Notes |
|----------|----------|-------|
| `opencode.json` | `heimdall.json` | Filename change |
| `~/.config/opencode/` | `~/.config/heimdall/` | Directory change |
| `.opencode/` | `.heimdall/` | Project directory |
| No rules field | `rules` field | New enhanced feature |
| `instructions` only | `rules` + `instructions` | Both supported |

## Troubleshooting

### Rules Not Loading

1. **Check file paths**: Ensure paths are correct and files exist
2. **Verify permissions**: Check file read permissions
3. **Check enabled field**: Ensure `enabled: true` or omitted
4. **Review logs**: Use `--print-logs --log-level DEBUG`
5. **Check size limits**: Verify files don't exceed `maxSize`

### Priority Issues

1. Use debug logging to see load order
2. Remember: lower priority loads first
3. Higher priority content appears later and can override
4. Default priority is 50 if not specified

### Configuration Validation

```bash
# Check configuration loading
./bin/heimdall --print-logs --log-level DEBUG 2>&1 | grep config

# Test specific configuration
./bin/heimdall --config test-config.json --print-logs

# Verify rules loading
./bin/heimdall --print-logs 2>&1 | grep "loaded rule files"
```

## Best Practices

1. **Start Simple**: Begin with minimal config, add features as needed
2. **Use Priorities Wisely**: Reserve extremes (0-20, 80-100) for special cases
3. **Document Rules**: Use clear, descriptive filenames
4. **Test Changes**: Validate configuration after modifications
5. **Version Control**: Track config changes in git
6. **Team Standards**: Share base rules via low priority (0-20)
7. **Local Overrides**: Use high priority (80-100) for local customization
8. **Size Limits**: Set reasonable limits to prevent issues

## Related Documentation

- [Enhanced Rules System](../development/ENHANCED_RULES.md)
- [AGENTS Discovery](../development/AGENTS_DISCOVERY.md)
- [Logging Guide](../development/LOGGING.md)
- [Development Guide](../development/AGENTS.md)