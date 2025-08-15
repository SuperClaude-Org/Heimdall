# Heimdall Code Style and Conventions

## Zig Code Style (Build System)
- **File Naming**: snake_case (e.g., `patch_format.zig`, `main.zig`)
- **Function Naming**: camelCase for functions
- **Constant Naming**: UPPER_SNAKE_CASE for constants
- **Type Naming**: PascalCase for types and structs
- **Indentation**: 4 spaces
- **Line Length**: Prefer 100 characters max
- **Comments**: Use `//` for single-line, document public APIs
- **Error Handling**: Use Zig's error unions and handle all errors explicitly
- **Memory**: Prefer stack allocation, use allocators explicitly

## TypeScript/JavaScript Style
- **File Naming**: kebab-case for files (e.g., `heimdall-cli.ts`)
- **Module System**: ES modules (`import`/`export`)
- **TypeScript**: Strict mode enabled
- **Target**: ES2022
- **Module Resolution**: Bundler mode
- **Formatting**: Prettier for .js, .jsx, .ts, .tsx, .json, .md files
- **Type Annotations**: Always use explicit types for function parameters and returns
- **Async/Await**: Prefer over callbacks and promises

## Project Structure Conventions
- **Build artifacts**: Place in `build/bin/` or `dist/`
- **Patches**: Store in `build/patches/` as `.hpatch.json` files
- **Documentation**: Markdown files in `docs/` with clear categories
- **Tests**: Organize in `tests/` with subdirectories for different test types
- **Configuration**: JSON/YAML files in `config/` or project root

## Git Conventions
- **Branching**: Use feature branches (`feature/`, `fix/`, `docs/`)
- **Commits**: Clear, concise messages describing the change
- **Vendor Directory**: Always git-ignored, pulled fresh during setup
- **.gitignore**: Comprehensive exclusion of build artifacts and dependencies

## Documentation Style
- **Markdown**: Use for all documentation
- **Headers**: Use ATX-style headers (`#`, `##`, etc.)
- **Code Blocks**: Always specify language for syntax highlighting
- **Examples**: Include practical examples in documentation
- **ASCII Art**: Heimdall branding in key locations

## Patch Format Convention
- **Format**: JSON-based `.hpatch.json` files
- **Version**: Include version field (currently "1.0")
- **Matchers**: Support multiple fallback strategies
- **Confidence**: Include confidence thresholds for fuzzy matching

## Testing Conventions
- **Test Files**: Name with `.test.` suffix
- **Test Structure**: Organize by functionality
- **Scripts**: Bash scripts for integration testing
- **Rules**: Markdown files for rule definitions

## Naming Conventions
- **Project Name**: "Heimdall" (not "heimdall" or "HEIMDALL")
- **Binary Names**: `heimdall-build`, `heimdall-patcher`
- **Config Files**: `heimdall.json` (not `opencode.json`)
- **ASCII Art**: Consistent Heimdall branding

## Error Handling
- **Zig**: Use error unions, handle all errors
- **TypeScript**: Use try-catch, provide meaningful error messages
- **Scripts**: Check return codes, provide clear error output
- **User Feedback**: Always provide actionable error messages