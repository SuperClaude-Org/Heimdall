# Vendor Changelog

This file tracks updates to the vendored opencode dependency.

## Format

Each entry should include:
- Date of update
- opencode version (from their package.json)
- Notable changes or features
- Any conflicts resolved
- Heimdall-specific adjustments made

---

## [Initial] - 2024-08-14

### opencode Version
- Version: 0.4.45
- Commit: Latest from dev branch

### Changes
- Initial vendor import using git subtree
- Added opencode as subtree at `vendor/opencode`
- No modifications to original code

### Heimdall Adjustments
- Created wrapper scripts in `bin/`
- Added rebranding script for user-facing elements
- Set up TypeScript configuration for vendor imports

### Notes
- Using subtree with `--squash` flag for cleaner history
- Tracking `dev` branch of sst/opencode

---

## Update Template

```markdown
## [Update X] - YYYY-MM-DD

### opencode Version
- Previous: X.X.X
- Updated to: X.X.X
- Commits pulled: X

### Notable Changes
- Feature: ...
- Fix: ...
- Breaking: ...

### Conflicts Resolved
- File: `path/to/file` - Description of resolution

### Heimdall Adjustments
- Updated: ...
- Fixed: ...

### Testing
- [ ] CLI commands work
- [ ] Build succeeds
- [ ] Tests pass
- [ ] Rebranding applied correctly

### Notes
- Any special considerations
```