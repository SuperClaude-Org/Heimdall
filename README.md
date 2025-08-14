# Heimdall CLI

> AI-powered CLI assistant based on opencode

```
╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  
╠═╣║╣ ║║║║ ║║╠═╣║  ║  
╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝
```

## Overview

Heimdall is a powerful AI-powered command-line interface that extends and customizes the opencode CLI with additional features and branding. It provides seamless integration with AI models for code generation, analysis, and automation tasks.

## Features

- 🤖 **AI-Powered Assistance** - Leverage Claude, GPT-4, and other models
- 🔧 **Code Generation** - Generate code, tests, and documentation
- 📦 **Vendor Management** - Built on opencode with easy updates
- 🎨 **Custom Branding** - Heimdall-themed interface
- 🔄 **Seamless Updates** - Pull latest opencode improvements
- ⚡ **Fast Performance** - Built with Bun for speed

## Installation

### Prerequisites

- Node.js >= 18.0.0
- Bun runtime (for development)
- Git

### Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/heimdall.git
cd heimdall

# Install dependencies
bun install

# Build the project
bun run build

# Run Heimdall
./bin/heimdall --help
```

### Global Installation

```bash
# Install globally with npm
npm install -g heimdall-cli

# Or with bun
bun install -g heimdall-cli

# Run from anywhere
heimdall --help
```

## Usage

### Basic Commands

```bash
# Show help
heimdall --help

# Check version
heimdall --version

# Run a command
heimdall run [command]

# Start interactive mode
heimdall chat
```

### Configuration

Create a configuration file at `~/.heimdall/config.json`:

```json
{
  "defaultModel": "claude-3-5-sonnet-latest",
  "defaultProvider": "anthropic",
  "apiKeys": {
    "anthropic": "your-api-key",
    "openai": "your-api-key"
  }
}
```

### Environment Variables

```bash
export HEIMDALL_DEFAULT_MODEL="claude-3-5-sonnet-latest"
export HEIMDALL_DEFAULT_PROVIDER="anthropic"
export HEIMDALL_CONFIG_PATH="~/.heimdall"
```

## Architecture

Heimdall uses a Git subtree approach to vendor opencode:

```
heimdall/
├── vendor/opencode/  # Subtree of sst/opencode
├── src/             # Heimdall-specific code
├── scripts/         # Build and maintenance
└── bin/            # CLI executables
```

This approach provides:
- **Self-contained repository** - No submodule complexity
- **Easy updates** - Pull upstream changes with one command
- **Custom modifications** - Rebrand and extend as needed
- **Version control** - Track all changes in one repo

## Development

### Setup Development Environment

```bash
# Install dependencies
bun install

# Run in development mode
bun run dev

# Run tests
bun test
```

### Update Vendored opencode

```bash
# Pull latest opencode changes
npm run update:vendor

# Or manually
git subtree pull --prefix=vendor/opencode opencode dev --squash
npm run rebrand
```

### Project Scripts

- `npm run build` - Build the project
- `npm run dev` - Run in development mode
- `npm run test` - Run tests
- `npm run rebrand` - Apply Heimdall branding
- `npm run update:vendor` - Update opencode vendor

## Documentation

- [Development Guide](docs/DEVELOPMENT.md) - Development workflow and setup
- [Vendor Management](docs/VENDOR_MANAGEMENT.md) - Managing the vendored opencode
- [Integration Plan](Heimdall.md) - Original integration strategy

## Contributing

We welcome contributions! Please see our [Development Guide](docs/DEVELOPMENT.md) for details on:

1. Setting up your development environment
2. Making changes
3. Testing your modifications
4. Submitting pull requests

## Versioning

Heimdall follows semantic versioning:
- **Major**: Breaking changes to CLI interface
- **Minor**: New features or commands
- **Patch**: Bug fixes and minor improvements

The vendored opencode version is tracked separately in `VENDOR_CHANGELOG.md`.

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Credits

Heimdall is built on top of [opencode](https://github.com/sst/opencode) by SST. We're grateful for their excellent work on the core CLI functionality.

## Support

- 📖 [Documentation](docs/)
- 🐛 [Issue Tracker](https://github.com/yourusername/heimdall/issues)
- 💬 [Discussions](https://github.com/yourusername/heimdall/discussions)

---

*Heimdall - Guarding the bridge between developers and AI*