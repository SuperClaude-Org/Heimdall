# Heimdall Project Overview

## Purpose
Heimdall is a customized version of the opencode CLI featuring AI-powered assistance, enhanced with Zig-based build system, smart patching, and Heimdall branding throughout. The project aims to patch the upstream https://github.com/SuperClaude-Org/heimdall_opencode repository with consistent Heimdall branding and UI enhancements.

## Key Features
- AI-Powered Assistance (Claude, GPT-4, and other models)
- Zig Build System (Fast, reliable builds with intelligent patching)
- Smart Patching (Fuzzy matching and automatic conflict resolution)
- Clean Architecture (Vendor management with pristine upstream)
- Custom Branding (Heimdall identity throughout)

## Tech Stack
- **Primary**: Zig (build system), TypeScript/JavaScript (application logic)
- **Build System**: Zig compiler (0.11.0+) with custom build.zig
- **Runtime**: Bun runtime (optional, for JavaScript dependencies)
- **Dependencies**: Node.js (18.0.0+), Git
- **Package Management**: npm scripts for orchestration

## Architecture
- `build/` - Zig-based intelligent build system with 6-stage pipeline
- `vendor/opencode/` - Git-ignored upstream opencode source (pulled fresh during setup)
- `config/` - Application configuration
- `patches/` - JSON-based patch definitions (.hpatch.json format)
- `docs/` - Architecture, development, and user documentation

## Build Pipeline (6 Stages)
1. **Update** - Pull latest from upstream
2. **Prepare** - Set up build environment  
3. **Transform** - Apply patches and branding
4. **Verify** - Check completeness
5. **Build** - Compile binaries
6. **Finalize** - Package and cleanup