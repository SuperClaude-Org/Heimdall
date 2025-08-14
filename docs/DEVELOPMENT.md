# Heimdall Development Guide

## Getting Started

### Prerequisites

- Node.js >= 18.0.0
- Bun (for building and running TypeScript)
- Git

### Initial Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/heimdall.git
cd heimdall
```

2. Install dependencies:
```bash
bun install
```

3. Build the project:
```bash
bun run build
```

4. Test the CLI:
```bash
./bin/heimdall --help
```

## Development Workflow

### Running in Development Mode

```bash
# Run directly with bun
bun run dev

# Or use the bin script
./bin/heimdall [command]
```

### Making Changes

#### Heimdall-Specific Code

All Heimdall-specific code goes in the `src/` directory:

- `src/cli/` - CLI wrapper and configuration
- `src/commands/` - Custom Heimdall commands (if any)
- `src/utils/` - Utility functions

#### Modifying Vendored Code

⚠️ **Avoid modifying vendored code directly!**

If you must modify vendor/opencode:
1. Make changes minimal and well-documented
2. Create a patch file: `git diff > patches/my-change.patch`
3. Document the change in `patches/README.md`
4. Be prepared to reapply after updates

### Building

```bash
# Full build
bun run build

# Build only Heimdall code
bun run build:heimdall

# Build only vendor code
bun run build:vendor
```

### Testing

```bash
# Run all tests
bun test

# Run specific test file
bun test tests/integration/cli.test.ts

# Run with coverage
bun test --coverage
```

## Project Structure

```
heimdall/
├── bin/                    # Executable scripts
│   ├── heimdall           # Main CLI entry (TypeScript)
│   └── heimdall-launcher  # Shell launcher
├── src/                   # Heimdall source code
│   └── cli/              # CLI implementation
│       ├── index.ts      # Entry point
│       └── heimdall-config.ts # Configuration
├── vendor/               # Vendored dependencies
│   └── opencode/        # Subtree of sst/opencode
├── scripts/             # Build and maintenance scripts
├── tests/              # Test files
└── docs/              # Documentation
```

## Configuration

### Environment Variables

- `HEIMDALL_VERSION` - Override version number
- `HEIMDALL_CONFIG_PATH` - Custom config directory
- `HEIMDALL_CACHE_PATH` - Custom cache directory
- `HEIMDALL_DEFAULT_MODEL` - Default AI model
- `HEIMDALL_DEFAULT_PROVIDER` - Default provider

### Configuration File

Heimdall looks for configuration in `~/.heimdall/config.json`:

```json
{
  "defaultModel": "claude-3-5-sonnet-latest",
  "defaultProvider": "anthropic",
  "theme": {
    "primaryColor": "#FFD700",
    "secondaryColor": "#4169E1"
  }
}
```

## Adding Custom Commands

To add a custom Heimdall command:

1. Create command file in `src/commands/`:
```typescript
// src/commands/custom.ts
export class CustomCommand {
  static command = 'custom';
  static describe = 'Custom Heimdall command';
  
  static builder(yargs) {
    return yargs.option('example', {
      describe: 'Example option',
      type: 'string'
    });
  }
  
  static async handler(argv) {
    console.log('Custom command executed!');
  }
}
```

2. Register in CLI wrapper:
```typescript
// src/cli/index.ts
import { CustomCommand } from '../commands/custom';
// Add to yargs configuration
```

## Debugging

### Enable Debug Logs

```bash
# Set log level
./bin/heimdall --log-level=debug [command]

# Enable all logs
DEBUG=* ./bin/heimdall [command]
```

### Using VS Code

`.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Heimdall",
      "runtimeExecutable": "bun",
      "program": "${workspaceFolder}/bin/heimdall",
      "args": ["--help"],
      "console": "integratedTerminal"
    }
  ]
}
```

## Common Tasks

### Update Vendored opencode
```bash
npm run update:vendor
```

### Rebrand After Manual Changes
```bash
npm run rebrand
```

### Create Distribution Build
```bash
bun run build
bun build --compile bin/heimdall --outfile dist/heimdall
```

### Run Linting
```bash
bun run lint
```

## Troubleshooting

### Bun Not Found
Install bun:
```bash
curl -fsSL https://bun.sh/install | bash
```

### TypeScript Errors
```bash
# Check TypeScript configuration
bun run typecheck

# Clear cache and rebuild
rm -rf node_modules dist
bun install
bun run build
```

### Import Errors
Ensure paths in `tsconfig.json` are correct:
```json
{
  "paths": {
    "@vendor/opencode/*": ["./vendor/opencode/packages/opencode/src/*"]
  }
}
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Add tests for new functionality
4. Ensure all tests pass
5. Update documentation
6. Submit a pull request

## Release Process

1. Update version in `package.json`
2. Update CHANGELOG.md
3. Build and test thoroughly
4. Tag the release: `git tag v0.1.0`
5. Push tags: `git push --tags`
6. Create GitHub release
7. Publish to npm (if applicable)