# Task Completion Checklist

## Before Making Changes
- [ ] Check git status and current branch
- [ ] Ensure vendor/opencode is initialized (run setup.sh if needed)
- [ ] Verify Zig compiler is available and working
- [ ] Review existing patches to understand current branding state

## During Development
- [ ] Follow Zig conventions for build system code
- [ ] Maintain patch file JSON structure and validation
- [ ] Test changes with --dry-run before applying
- [ ] Use verbose mode for debugging issues

## Code Quality Checks
- [ ] Run `npm run zig:build` to verify Zig code compiles
- [ ] Run `npm run zig:test` for Zig unit tests
- [ ] Run `npm run patch:verify` to validate patch files
- [ ] Test patch application with `npm run patch:apply --dry-run`

## Before Commit
- [ ] Run full build pipeline: `npm run build`
- [ ] Verify all patches apply successfully
- [ ] Check that branding is consistent throughout
- [ ] Ensure no build artifacts are included in git
- [ ] Test the final built system works correctly

## Documentation Updates
- [ ] Update README.md if architecture changes
- [ ] Update version in VERSION file if needed
- [ ] Document any new patch patterns or strategies
- [ ] Update build configuration if changed

## Final Validation
- [ ] Run complete test suite: `npm test`
- [ ] Verify upstream compatibility with original opencode
- [ ] Check that all Heimdall branding is properly applied
- [ ] Ensure build system can handle future upstream updates