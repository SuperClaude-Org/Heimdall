# Patching Approaches Comparison

## Current Situation

After updating vendor from upstream, we have:
- ✅ **Patch 003** (ASCII art): Applied successfully 
- ❌ **Patch 001** (complete branding): Failed due to line number changes
- ❌ **Patch 002** (enhanced agents): Failed due to line number changes

## Traditional Git Patches vs Pattern-Based Approach

### Traditional Git Patch Example
```diff
@@ -84,9 +85,9 @@ export namespace Server {
         openAPISpecs(app, {
           documentation: {
             info: {
-              title: "opencode",
+              title: "heimdall",
```
**Problem**: Expects line 84, but code is now at line 82 → FAILS

### Pattern-Based Approach
```json
{
  "search": "title: \"opencode\"",
  "replace": "title: \"heimdall\"",
  "context": "openAPISpecs.*documentation"
}
```
**Advantage**: Finds the text regardless of line number → SUCCEEDS

## Real-World Test Case

### File: `server.ts`
- Current state has `title: "opencode"` at lines 87 and 1132
- Traditional patch expects it at line 84 → **FAILS**
- Pattern-based would find both occurrences → **SUCCEEDS**

### File: `bin/opencode`
- Needs multiple replacements (OPENCODE_BIN_PATH, binary names, etc.)
- Traditional patch fails if even one line shifts
- Pattern-based handles each replacement independently

## Comparison Table

| Aspect | Traditional Patches | Pattern-Based |
|--------|-------------------|---------------|
| **Line number sensitivity** | Very high - fails if lines shift | None - finds text anywhere |
| **Upstream resilience** | Poor - breaks on most updates | Good - survives most changes |
| **Complexity handling** | Excellent - can refactor code | Limited - text replacement only |
| **Readability** | Diff format, harder to read | JSON format, self-documenting |
| **Debugging** | Hard to identify why it failed | Clear reporting per pattern |
| **Partial application** | All or nothing | Can skip failed patterns |
| **Backup/Revert** | Via git | Built-in backup system |
| **Context awareness** | Limited to surrounding lines | Regex-based context matching |

## Recommended Hybrid Approach

### Use Traditional Patches For:
1. **Complex code changes**
   - Adding new functions/classes
   - Modifying algorithms
   - Structural refactoring

2. **File additions/deletions**
   - Creating new files
   - Removing entire files
   - Moving files

### Use Pattern-Based For:
1. **Branding/naming changes**
   - "opencode" → "heimdall"
   - API titles and descriptions
   - Error messages

2. **Configuration values**
   - Version strings
   - URLs
   - Default settings

3. **Simple UI changes**
   - ASCII art
   - Status bar text
   - Help messages

## Implementation Strategy

### Phase 1: Extract Simple Changes
Move these from patches 001-002 to patterns:
- Binary name replacements
- API documentation strings  
- Directory names (.opencode → .heimdall)
- Workflow names

### Phase 2: Keep Complex Changes
Maintain as traditional patches:
- Import additions
- Function modifications
- New features

### Phase 3: Combine Both
```bash
# Apply patterns first (more likely to succeed)
node scripts/apply-branding.js apply

# Then apply remaining patches (complex changes)
npm run patch:apply
```

## Success Metrics

### Current Approach (All Traditional)
- Success rate after upstream update: ~33% (1 of 3 patches)
- Manual intervention required: High
- Time to fix: 30-60 minutes

### Hybrid Approach (Pattern + Traditional)
- Expected success rate: ~80-90%
- Manual intervention: Low
- Time to fix: 5-10 minutes

## Conclusion

The pattern-based approach would solve most of our current patching failures while maintaining the power of traditional patches for complex changes. This hybrid strategy provides:

1. **Better maintainability** - Easier updates from upstream
2. **Clearer organization** - Branding separate from features
3. **Improved reliability** - Higher success rate
4. **Faster recovery** - Quick fixes when updates break patches

The investment in setting up pattern-based patching would pay off quickly given the frequency of upstream updates and the fragility of line-based patches for simple text replacements.