# Task Completion Checklist

When completing a development task in Heimdall, follow these steps:

## 1. Code Quality Checks

### For Zig Code (Build System)
```bash
# Build and test
cd build && zig build
cd build && zig build test

# Verify binaries work
./build/bin/heimdall-build --help
./build/bin/heimdall-patcher --help
```

### For TypeScript/JavaScript
```bash
# Format code with Prettier
npx prettier --write "**/*.{js,jsx,ts,tsx,json,md}"

# Type checking (if TypeScript)
npx tsc --noEmit

# Linting (if configured)
# Note: No ESLint currently configured, consider adding
```

## 2. Testing
```bash
# Run test suite
npm test

# Test build pipeline
npm run build:dry  # Dry run first
npm run build      # Actual build

# Integration test
bash test_complete_setup.sh
```

## 3. Documentation Updates
- Update relevant documentation in `docs/`
- Update README.md if features changed
- Update CHANGELOG.md with changes
- Ensure code comments are clear

## 4. Patch Verification
If patches were modified:
```bash
# Verify all patches apply correctly
npm run patch:verify

# Test patch application
npm run patch:apply --dry-run
```

## 5. Git Workflow
```bash
# Check what changed
git status
git diff

# Stage changes
git add -A  # or selective git add

# Commit with clear message
git commit -m "feat: description" # or fix:, docs:, refactor:, test:

# Push to branch
git push origin <branch-name>
```

## 6. Build Verification
```bash
# Clean build test
npm run clean
bash setup.sh
npm run build
```

## 7. Final Checks
- [ ] Code compiles without warnings
- [ ] Tests pass
- [ ] Documentation is updated
- [ ] Commit message is clear
- [ ] No sensitive information in code
- [ ] Vendor directory not committed
- [ ] Build artifacts not committed

## 8. Special Considerations

### When Modifying Build System
- Test both `heimdall-build` and `heimdall-patcher`
- Verify all 6 build stages work
- Check dry-run mode works

### When Modifying Patches
- Test against fresh vendor checkout
- Verify fuzzy matching still works
- Update patch documentation

### When Adding Dependencies
- Update package.json
- Document why dependency is needed
- Consider impact on build size

## 9. Continuous Integration
If CI is configured:
- Ensure all CI checks pass
- Review any automated feedback
- Address any failing checks

## 10. Communication
- Update team on significant changes
- Document breaking changes clearly
- Create PR with detailed description