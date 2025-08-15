# Testing Heimdall CLI

## Build & Compile

### Quick Build
```bash
# Standard build (keeps existing vendor state)
./build.sh

# Clean build (resets vendor and reapplies patches)
./build.sh clean
```

### Manual Build Steps
```bash
# 1. Install dependencies
npm install

# 2. Apply patches
npm run patch:apply

# 3. Make executable
chmod +x bin/heimdall

# 4. Test
./bin/heimdall --help
```

## Testing Commands

### Basic Tests
```bash
# Show version
./bin/heimdall --version

# Show help with branding
./bin/heimdall --help

# List available models
./bin/heimdall models

# Auth management
./bin/heimdall auth --help
./bin/heimdall auth status

# Agent management  
./bin/heimdall agent --help
```

### Run Test Script
```bash
# Comprehensive test
./test-heimdall.sh
```

## Configuration

Heimdall looks for `heimdall.json` (not `opencode.json`):

```json
{
  "models": [
    {
      "name": "anthropic/claude-3-5-sonnet-latest",
      "provider": "anthropic"
    }
  ]
}
```

## Setting Up API Keys

Before using Heimdall with AI models, you need to set up API keys:

```bash
# For Anthropic Claude
./bin/heimdall auth login anthropic

# For OpenAI
./bin/heimdall auth login openai

# For other providers
./bin/heimdall auth login <provider>
```

## Running Heimdall

### Interactive TUI Mode
```bash
# Start in current directory
./bin/heimdall

# Start in specific project
./bin/heimdall /path/to/project
```

### Run with Message
```bash
# Simple command
./bin/heimdall run "What files are in this directory?"

# With specific model
./bin/heimdall run -m anthropic/claude-3-5-sonnet-latest "Explain this codebase"

# Continue previous session
./bin/heimdall run --continue "Add more details"
```

### Server Mode
```bash
# Start server on default port
./bin/heimdall serve

# Start on specific port
./bin/heimdall serve --port 8080
```

## Patch Management

### View Applied Patches
```bash
npm run patch:status
```

### Revert Patches
```bash
npm run patch:revert
```

### Update from Upstream
```bash
# This will pull latest opencode and reapply patches
./scripts/update.sh
```

## Troubleshooting

### If build fails:
1. Clean build: `./build.sh clean`
2. Check patch status: `git status vendor/`
3. Manually revert vendor: `git checkout vendor/`
4. Reapply patches: `npm run patch:apply`

### If commands show "opencode" instead of "heimdall":
- Patches weren't applied correctly
- Run: `npm run patch:apply`

### If module errors occur:
- Dependencies might be out of sync
- Run: `cd vendor/opencode && bun install`

## Verification Checklist

✅ **Build & Compile**
- [ ] `./build.sh clean` completes without errors
- [ ] Binary is executable

✅ **Branding**
- [ ] Help shows "HEIMDALL" ASCII art
- [ ] Commands show "heimdall" not "opencode"
- [ ] Config file is `heimdall.json`

✅ **Core Functions**
- [ ] `--version` works
- [ ] `--help` displays correctly
- [ ] `auth` commands work
- [ ] `models` lists available models

✅ **With API Keys**
- [ ] TUI mode starts
- [ ] Can run simple commands
- [ ] Server mode starts

## Success Indicators

When everything is working correctly:

1. **ASCII Art**: You'll see the HEIMDALL banner
2. **Command Names**: All commands prefixed with `heimdall`
3. **Config File**: Uses `heimdall.json` not `opencode.json`
4. **Version**: Shows "Heimdall v0.1.0 - Based on opencode v0.4.45"

## Next Steps

After successful testing:

1. Set up your API keys with `./bin/heimdall auth login <provider>`
2. Create your `heimdall.json` configuration
3. Start using Heimdall: `./bin/heimdall`

For development and customization, see `docs/VENDOR_MANAGEMENT.md`