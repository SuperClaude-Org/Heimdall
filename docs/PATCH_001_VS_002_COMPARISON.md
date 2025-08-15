# Comparison: Patch 001 vs Patch 002

## Executive Summary

**Patch 001**: Pure branding changes (opencode → heimdall)
**Patch 002**: Branding + Enhanced rules system with AGENTS.md discovery

## Detailed Comparison

### Files Modified

Both patches modify the same 17 files, but with different content in some files.

### Identical Changes (Both Patches)

#### 1. Binary Script (`bin/opencode`)
- `OPENCODE_BIN_PATH` → `HEIMDALL_BIN_PATH`
- `opencode-${platform}-${arch}` → `heimdall-${platform}-${arch}`
- Binary names: `opencode` → `heimdall`
- Error messages updated

#### 2. Agent Command (`src/cli/cmd/agent.ts`)
- `.opencode/agent/*.md` → `.heimdall/agent/*.md`
- Directory path changes

#### 3. GitHub Command (`src/cli/cmd/github.ts`)
- `.github/workflows/opencode.yml` → `.github/workflows/heimdall.yml`
- Workflow name changes

#### 4-10. Other CLI Commands
- `mcp.ts`, `run.ts`, `serve.ts`, `tui.ts`, `upgrade.ts`
- `error.ts`, `ui.ts`
- All have identical branding changes in both patches

#### 11. Global Index (`src/global/index.ts`)
- Identical changes for path constants

#### 12. Main Index (`src/index.ts`)
- Identical branding changes

#### 13. Installation (`src/installation/index.ts`)
- Version and naming changes

#### 14. MCP (`src/mcp/index.ts`)
- Branding in MCP server names

#### 15. Provider (`src/provider/provider.ts`)
- Provider naming changes

#### 16. Server (`src/server/server.ts`)
- API documentation title changes
- Both patches fail here due to line number changes

### Key Differences

#### 1. Config File (`src/config/config.ts`)

**Patch 001 (Simple Branding)**:
```diff
- for (const file of ["opencode.jsonc", "opencode.json"]) {
+ for (const file of ["heimdall.jsonc", "heimdall.json"]) {
- ...(await Filesystem.globUp(".opencode/agent/*.md", app.path.cwd, app.path.root)),
+ ...(await Filesystem.globUp(".heimdall/agent/*.md", app.path.cwd, app.path.root)),
```
- Only renames config files and directories
- Removes one config file from loading sequence

**Patch 002 (Enhanced with Rules System)**:
```diff
+ // Enhanced rule configuration with priority system
+ export const RuleConfig = z.union([
+   z.string(),
+   z.object({
+     path: z.string().describe("Path to rule file"),
+     priority: z.number().min(0).max(100).default(50),
+     required: z.boolean().default(false),
+     maxSize: z.number().optional(),
+     enabled: z.boolean().default(true)
+   })
+ ])
+ 
+ rules: z.array(RuleConfig).optional().describe("Custom rule files"),
+ rulesConfig: RulesGlobalConfig.optional()
```
- Adds complete rules configuration system
- Adds schema validation for rules
- Adds priority-based loading
- Maintains backward compatibility

#### 2. System Prompt (`src/session/system.ts`)

**Patch 001**: No changes to this file

**Patch 002 (Major Enhancement)**:
```typescript
+ // Rule file interface for priority system
+ interface RuleFile {
+   path: string
+   content: string
+   priority: number
+   size: number
+   mtime: Date
+   source: 'rules' | 'instructions' | 'default'
+   required: boolean
+ }

+ // Helper function to resolve rule paths
+ async function resolveRulePath(...)
```

Adds complete rule discovery system with:
- Priority-based loading (0-100)
- Multiple sources (rules field, instructions, default AGENTS.md)
- Glob pattern support
- Size limits
- Required/optional rules
- Detailed logging
- Error handling with failOnMissing option

### Feature Comparison Table

| Feature | Patch 001 | Patch 002 |
|---------|-----------|-----------|
| **Branding** | ✅ Complete | ✅ Complete |
| **Config renaming** | ✅ opencode → heimdall | ✅ opencode → heimdall |
| **Rules field in config** | ❌ No | ✅ Yes |
| **Priority system** | ❌ No | ✅ Yes (0-100) |
| **AGENTS.md discovery** | ❌ Standard | ✅ Enhanced |
| **Glob patterns** | ❌ No | ✅ Yes |
| **Size limits** | ❌ No | ✅ Yes |
| **Required rules** | ❌ No | ✅ Yes |
| **Logging** | ❌ No | ✅ Detailed |
| **Backward compatible** | ✅ Yes | ✅ Yes |

### Configuration Examples

#### With Patch 001
```json
{
  "model": "anthropic/claude-3",
  "instructions": ["AGENTS.md"]  // Simple array
}
```

#### With Patch 002
```json
{
  "model": "anthropic/claude-3",
  "rules": [
    "AGENTS.md",  // Simple string (priority 50)
    {
      "path": "~/company-standards.md",
      "priority": 10,
      "required": true
    },
    {
      "path": "docs/*.rules.md",
      "priority": 90,
      "maxSize": 50000
    }
  ],
  "rulesConfig": {
    "failOnMissing": true,
    "logLevel": "debug",
    "maxTotalSize": 1000000
  }
}
```

### Rule Loading Order (Patch 002)

1. **Priority 0-49**: Early rules (base configuration)
   - Company standards
   - Global defaults
   
2. **Priority 50**: Default priority
   - AGENTS.md (if no rules field specified)
   - Simple string rules
   
3. **Priority 51-100**: Override rules
   - Project-specific rules
   - Critical overrides

### Implementation Differences

#### Patch 001 Approach
- Minimal changes
- Direct string replacements
- No new functionality
- Easier to maintain
- Less likely to break with updates

#### Patch 002 Approach
- Significant new functionality
- Complex rule resolution logic
- Enhanced error handling
- More powerful but more complex
- Higher maintenance burden

## Recommendations

### If You Want Simple Branding
Use **Patch 001** or the pattern-based approach:
- Lower risk
- Easier to maintain
- Sufficient for branding needs

### If You Need Enhanced Rules System
Use **Patch 002** features:
- Priority-based rule loading
- Better organization of instructions
- More control over rule discovery
- Professional configuration management

### Hybrid Approach (Recommended)
1. **Extract branding** from both patches → Pattern-based system
2. **Extract rules system** from Patch 002 → Separate feature patch
3. **Apply independently**:
   ```bash
   # Apply branding (always works)
   node scripts/apply-branding.js
   
   # Apply rules feature (when needed)
   git apply patches/004-enhanced-rules-system.patch
   ```

## Conclusion

**Patch 002 is NOT just a duplicate** - it contains significant functionality:
- Complete rules configuration system
- Priority-based loading
- Enhanced AGENTS.md discovery
- Professional error handling

The patches should be:
1. **Split** into branding vs features
2. **Renamed** for clarity:
   - `001-heimdall-branding.patch`
   - `002-enhanced-rules-system.patch`
3. **Applied selectively** based on needs

The rules system in Patch 002 is valuable and should be preserved as a separate feature enhancement.