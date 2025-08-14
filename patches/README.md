# Heimdall Patches Documentation

## Overview

This directory contains git patches that rebrand opencode to Heimdall. All user-facing elements are changed while preserving compatibility with the opencode ecosystem.

## Active Patches

### 001-heimdall-complete-branding.patch

**Purpose**: Comprehensive rebranding of all user-facing elements from "opencode" to "heimdall"

**Files Modified**: 20+ files across the codebase

**Changes Include**:

#### Core CLI Branding
- `scriptName` changed to "heimdall" 
- ASCII logo replaced with Heimdall branding
- Log entries show "heimdall" instead of "opencode"

#### Command Descriptions
- All command descriptions updated (tui, run, serve, upgrade, etc.)
- Help text shows "heimdall" throughout

#### Configuration Files
- Config files: `heimdall.json`, `heimdall.jsonc` (was opencode.*)
- Directory paths: `.heimdall/` (was .opencode/)
- Global app name: "heimdall"

#### Installation & System
- User agent: `heimdall/${VERSION}`
- Binary names: `heimdall`, `heimdall.exe`
- Package patterns: `heimdall-${platform}-${arch}`
- Error messages reference "heimdall CLI"

#### Server & API
- API title and description: "heimdall api"
- HTTP headers: `X-Title: heimdall`
- Server messages: "heimdall server listening..."

#### GitHub Integration
- Workflow file: `.github/workflows/heimdall.yml`
- Comment triggers: `/heimdall` or `/hd` (was /opencode or /oc)
- Bot user: `heimdall-agent[bot]`
- Branch prefix: `heimdall/`
- Session logs: "heimdall session"

#### MCP & IDE
- Command checks for "heimdall"
- Placeholder examples use "heimdall"
- Error messages reference "heimdall"

## What's NOT Changed

To maintain compatibility with the opencode ecosystem:

1. **URLs** - All opencode.ai URLs remain unchanged
2. **Package imports** - Internal `@opencode-ai/` imports preserved
3. **GitHub repos** - References to `sst/opencode` unchanged
4. **GitHub Actions** - Uses `sst/opencode/github@latest`
5. **API endpoints** - External API URLs unchanged

## Applying Patches

```bash
# Apply all patches
npm run patch:apply

# Or manually
git apply patches/001-heimdall-complete-branding.patch
```

## Reverting Patches

```bash
# Revert all patches
npm run patch:revert

# Or manually
git apply --reverse patches/001-heimdall-complete-branding.patch
```

## Creating New Patches

1. Make changes to vendor files
2. Create patch: `git diff vendor/ > patches/XXX-description.patch`
3. Revert vendor changes
4. Test patch application

## Updating After Upstream Changes

When updating from upstream opencode:

1. Revert patches first
2. Pull upstream changes
3. Reapply patches
4. If conflicts occur, manually recreate the patch

## Testing

After applying patches, test that:

1. `heimdall --help` shows Heimdall branding
2. `heimdall --version` works
3. Commands show "heimdall" in descriptions
4. Configuration looks for `heimdall.json`
5. GitHub workflow uses `/heimdall` trigger