# Heimdall Development Guide for AI Agents

## Build & Test Commands

### Initial Setup
- **Clone & Setup**: `bash setup.sh` - Initializes vendor directory and builds Zig binaries
- **Manual Setup**: 
  ```bash
  git clone https://github.com/opencodeco/opencode.git vendor/opencode
  cd build && zig build && cd ..
  ./build/bin/heimdall-build
  ```

### Build Commands
- **Full Build**: `npm run build` or `./build/bin/heimdall-build`
- **Dry Run**: `npm run build:dry` or `./build/bin/heimdall-build --dry-run`
- **Verbose**: `npm run build:verbose` or `./build/bin/heimdall-build --verbose`
- **Force Build**: `npm run build:force` or `./build/bin/heimdall-build --force`
- **Zig Build**: `npm run zig:build` or `cd build && zig build -Doptimize=ReleaseFast`

### Testing
- **All Tests**: `npm test` or `./tests/run.sh`
- **Quick Tests**: `npm run test:quick` or `./tests/run.sh --quick`
- **Integration Tests**: `npm run test:integration` or `./tests/run.sh integration`
- **E2E Tests**: `npm run test:e2e` or `./tests/run.sh e2e`
- **Unit Tests**: `npm run test:unit` or `./tests/run.sh unit`

### Patch Management
- **Apply Patches**: `npm run patch:apply` or `./build/bin/heimdall-patcher apply`
- **Verify Patches**: `npm run patch:verify` or `./build/bin/heimdall-patcher verify`
- **List Patches**: `npm run patch:list` or `./build/bin/heimdall-patcher list`
- **Create Patch**: `npm run patch:create` or `./build/bin/heimdall-patcher create`

## Code Style & Conventions

### Zig Code (Build System)
- **File Naming**: snake_case (e.g., `patch_format.zig`, `main.zig`)
- **Functions**: camelCase for function names
- **Constants**: UPPER_SNAKE_CASE
- **Types**: PascalCase for types and structs
- **Indentation**: 4 spaces
- **Error Handling**: Use error unions, handle all errors explicitly
- **Memory**: Prefer stack allocation, use allocators explicitly

### TypeScript/JavaScript
- **TypeScript**: Strict mode enabled, target ES2022, module ESNext
- **Module Resolution**: Bundler mode
- **Imports**: Use path aliases:
  - `@heimdall/*` for src
  - `@vendor/opencode/*` for vendor code
  - `@vendor/tui/*` for TUI components
  - `@vendor/sdk/*` for SDK components
- **Formatting**: Prettier for .js, .jsx, .ts, .tsx, .json, .md files
- **Variables**: Prefer `const`, use descriptive names
- **Functions**: Keep focused, use async/await
- **Error Handling**: Provide meaningful error messages
- **Types**: Always use explicit types for function parameters and returns

### Project Structure
- **Build System**: `build/` - Zig-based build and patching system
- **Configuration**: `config/` - Application configuration files
- **Documentation**: `docs/` - Organized by architecture, development, and user guides
- **Tests**: `tests/` - Test suites with fixtures, integration, and e2e tests
- **Vendor**: `vendor/` - Git-ignored, pulled fresh during setup

### Patch Format
- **Format**: JSON-based `.hpatch.json` files in `build/patches/`
- **Version**: Include version field (currently "1.0")
- **Strategies**: Support multiple fallback strategies (exact, fuzzy, context)
- **Confidence**: Include confidence thresholds for fuzzy matching

### Git Conventions
- **Branching**: Feature branches (`feature/`, `fix/`, `docs/`)
- **Commits**: Clear messages with conventional prefixes (feat:, fix:, docs:, refactor:, test:)
- **Vendor**: Always git-ignored, never commit vendor directory

### ASCII Branding
- **Heimdall ASCII Art**: 
  ```
  ╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦
  ╠═╣║╣ ║║║║ ║║╠═╣║  ║
  ╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝
  ```
- Use in user-facing outputs, help messages, and documentation

## Development Workflow

### Making Changes
1. Create feature branch
2. Make changes following conventions
3. Test with `npm run build:dry` first
4. Run full build with `npm run build`
5. Test changes with `npm test`
6. Commit with clear message

### Task Completion Checklist
- [ ] Code compiles without warnings
- [ ] Tests pass
- [ ] Documentation updated
- [ ] Patches verified (if modified)
- [ ] No vendor files committed
- [ ] Build artifacts not committed
- [ ] Clear commit message

## Key Files
- **Build Config**: `build/config/build.yaml`
- **Branding Config**: `build/config/branding.yaml`
- **Main Config**: `config/heimdall.json`
- **Package Definition**: `package.json`
- **TypeScript Config**: `tsconfig.json`

## Common Operations

### Update Vendor
```bash
git -C vendor/opencode pull origin main
```

### Clean Build
```bash
npm run clean
rm -rf .build .zig-cache dist node_modules
```

### Run Heimdall (after build)
```bash
./bin/heimdall --help
./bin/heimdall --version
./bin/heimdall run "command"
```