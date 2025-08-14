# Heimdall CLI

> AI-powered CLI assistant based on opencode

```
╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  
╠═╣║╣ ║║║║ ║║╠═╣║  ║  
╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝
```

## Overview

Heimdall is a customized version of the opencode CLI with additional branding and features. It uses a clean vendor + patches approach to maintain customizations while allowing easy updates from upstream.

## Features

- 🤖 **AI-Powered Assistance** - Leverage Claude, GPT-4, and other models
- 🔧 **Code Generation** - Generate code, tests, and documentation
- 📦 **Clean Vendor Management** - Pristine vendor with patch-based customizations
- 🎨 **Heimdall Branding** - Custom branding and identity
- 🔄 **Easy Updates** - Pull latest opencode improvements with one command
- ⚡ **Fast Performance** - Built with Bun for speed

## Installation

### Prerequisites

- Node.js >= 18.0.0
- Bun runtime
- Git

### Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/heimdall.git
cd heimdall

# Install dependencies
bun install

# Apply customization patches
npm run patch:apply

# Run Heimdall
./bin/heimdall --help
```

## Usage

```bash
# Show help
heimdall --help

# Check version
heimdall --version

# Start interactive mode
heimdall

# Run a command
heimdall run "explain this code"
```

## Architecture

Heimdall uses a simple and maintainable architecture:

```
heimdall/
├── vendor/opencode/  # Pristine opencode (never modified)
├── patches/          # Git patches for customizations
├── bin/heimdall      # Simple launcher script
└── scripts/          # Maintenance scripts
```

### How It Works

1. **Vendor**: opencode is vendored via git subtree - never modified directly
2. **Patches**: All customizations are git patches in `patches/`
3. **Launcher**: Simple script that runs opencode with our environment
4. **Updates**: Pull upstream, reapply patches, done!

## Customization

### Apply Existing Patches
```bash
npm run patch:apply
```

### Create New Customization
```bash
# 1. Make changes to vendor files
vim vendor/opencode/...

# 2. Create patch
git diff vendor/ > patches/003-my-feature.patch

# 3. Revert vendor and test patch
git checkout vendor/
npm run patch:apply
```

## Updating from Upstream

```bash
# Automatic update
npm run update

# This will:
# 1. Revert patches
# 2. Pull latest opencode
# 3. Reapply patches
# 4. Report any conflicts
```

## Scripts

- `npm run dev` - Run Heimdall
- `npm run patch:apply` - Apply all patches
- `npm run patch:revert` - Revert all patches
- `npm run patch:list` - List available patches
- `npm run update` - Update vendor from upstream

## Documentation

- [Vendor Management](docs/VENDOR_MANAGEMENT.md) - How to manage vendor and patches

## Contributing

1. Fork the repository
2. Create your feature branch
3. Make changes (preferably as patches)
4. Test thoroughly
5. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Credits

Heimdall is built on top of [opencode](https://github.com/sst/opencode) by SST.

---

*Heimdall - Simple, maintainable, powerful*