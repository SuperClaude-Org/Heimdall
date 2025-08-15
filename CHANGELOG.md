# Changelog

## [2.0.0] - 2025-08-15

### Major Repository Reorganization

#### Added
- ✨ Unified `/build` directory for Zig-based build system
- 📝 Comprehensive documentation structure (`/docs/architecture`, `/docs/development`, `/docs/user`)
- 🔧 `setup.sh` script for easy initialization
- 📄 Consolidated `PATCHING_SYSTEM.md` documentation
- 🚀 Pure Zig build pipeline with 6-stage process

#### Changed
- 🏗️ Renamed `/patcher` → `/build` for clarity
- 📁 Reorganized documentation into logical categories
- 🔄 Updated all paths and configurations for new structure
- 📦 Vendor directory now git-ignored (pulled fresh during setup)
- ⚡ Migrated from mixed JS/Zig to pure Zig build system

#### Removed
- 🗑️ 10+ deprecated directories
- 🗑️ 50+ unnecessary files
- 🗑️ Old JavaScript build scripts
- 🗑️ Legacy patch formats
- 🗑️ Temporary build artifacts
- 🗑️ ~40% repository size reduction

#### Technical Details
- Build system: Zig 0.11.0+
- Patch format: `.hpatch.json`
- Configuration: YAML-based
- Architecture: Vendor + patches model

### Benefits
- **Lighter Repository**: Vendor excluded, ~60% smaller
- **Cleaner Structure**: 5 organized directories vs 15+ scattered
- **Better Documentation**: Clear separation of concerns
- **Easier Setup**: Single `setup.sh` script
- **Modern Build**: Pure Zig with intelligent patching

---

## [1.0.0] - Previous Version

Initial Heimdall implementation with JavaScript-based build system.