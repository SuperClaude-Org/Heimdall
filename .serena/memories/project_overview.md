# Heimdall CLI Project Overview

## Purpose
Heimdall is a customized version of the opencode CLI featuring AI-powered assistance with enhanced capabilities. It's a developer tool that provides:
- AI-powered CLI assistant functionality (using Claude, GPT-4, and other models)
- Intelligent code patching and build system
- Smart vendor management with upstream synchronization
- Custom branding and identity

## Tech Stack
- **Primary Language**: Zig (for build system and patching tools)
- **Secondary Languages**: TypeScript/JavaScript (for CLI application)
- **Runtime**: Node.js (>=18.0.0) with Bun as optional runtime
- **Build System**: Custom Zig-based build pipeline
- **Package Manager**: npm/bun
- **Version Control**: Git

## Architecture
The project consists of:
1. **Build System** (`build/`) - Zig-based intelligent patcher and build orchestrator
2. **Configuration** (`config/`) - Application and schema configurations
3. **Documentation** (`docs/`) - Architecture, development, and user guides
4. **Tests** (`tests/`) - Test suites and rule definitions
5. **Vendor Management** - Clean upstream management (vendor/ is git-ignored)

## Key Features
- 6-stage build pipeline (Update → Prepare → Transform → Verify → Build → Finalize)
- Intelligent patching with fuzzy matching and context-aware strategies
- Multiple matching strategies (exact, fuzzy, context-based)
- Confidence scoring for patch matches
- Backup and rollback support
- Cross-platform native binaries via Zig

## Dependencies
- Zig compiler (0.11.0 or later) - for building the patcher
- Git - for version control and vendor management
- Node.js/Bun - for JavaScript runtime
- Various npm packages (glob, yargs, zod, hono, ai, etc.)

## Project Status
The project is actively developed with a working build system, intelligent patcher, and comprehensive documentation. The vendor directory is managed separately and pulled fresh during setup.