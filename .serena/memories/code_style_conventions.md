# Code Style and Conventions

## Zig Code (Build System)
- **Memory Management**: Explicit allocators with proper defer cleanup
- **Error Handling**: Error unions `!T`, use `try`/`catch`/`errdefer`
- **Naming**: snake_case for variables/functions, PascalCase for types
- **Structure**: Clear separation between modules (patcher.zig, build.zig, etc.)
- **Comments**: Minimal but descriptive, focus on why not what

## TypeScript/JavaScript (Application)
- **Module System**: ES modules (`import`/`export`)
- **Package Structure**: Monorepo style with packages/ directory
- **Dependencies**: Listed in package.json with specific versions
- **Naming**: camelCase for variables/functions, PascalCase for types/classes

## Patch Files (.hpatch.json)
- **Version**: Always specify version field
- **Structure**: Hierarchical (patches > changes > matchers/strategies)
- **Strategies**: replace, inject_after, inject_before
- **Matchers**: exact, fuzzy, context-based with confidence thresholds
- **Descriptions**: Required for all patches and changes

## File Organization
- **Zig sources**: `build/src/` with logical module separation
- **Patches**: `build/patches/` with descriptive names
- **Config**: YAML format in `build/config/`
- **Documentation**: Markdown in `docs/` with clear hierarchy

## Branding Consistency
- **Case Sensitivity**: Preserve exact case (OpenCode → Heimdall, opencode → heimdall)
- **ASCII Art**: Consistent Heimdall symbol throughout
- **Whitelisting**: Preserve original URLs, copyright, and legal attribution