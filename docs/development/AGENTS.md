# Heimdall Development Guide for AI Agents

## Build & Test Commands
- **Build**: `npm run build` or `bash scripts/build.sh` - Builds Heimdall with vendor dependencies
- **Test**: `npm test` or `bash scripts/test.sh` - Runs full test suite
- **Dev**: `npm run dev` or `./bin/heimdall` - Run in development mode
- **Single test**: Use bash test scripts directly, e.g., `bash tests/integration/test-name.sh`
- **Patch management**: `npm run patch:apply`, `patch:revert`, `patch:list`, `patch:create`

## Code Style & Conventions
- **TypeScript**: Strict mode enabled, target ES2022, module ESNext
- **Imports**: Use path aliases `@heimdall/*` for src, `@vendor/opencode/*` for vendor code
- **Formatting**: No semicolons, 120 char line width (Prettier config from vendor)
- **Variables**: Prefer `const`, avoid `let`, use single-word names when possible
- **Functions**: Keep logic in single functions unless composable/reusable
- **Error handling**: Avoid `try/catch` where possible, use NamedError pattern for custom errors
- **Types**: Avoid `any`, use Zod schemas for validation, extend with zod-openapi
- **Async**: Use async/await, leverage Bun APIs like `Bun.file()` when available
- **Control flow**: Avoid `else` statements and unnecessary destructuring
- **File structure**: Extensions in `src/extensions/`, commands follow yargs pattern
- **ASCII branding**: Use Heimdall ASCII art (╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦) in user-facing outputs