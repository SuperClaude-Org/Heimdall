# Heimdall Intelligent Patcher

A Zig-based intelligent patching system that uses multiple matching strategies to apply patches reliably, even when upstream code changes.

## Features

- **Multi-Strategy Matching**: Exact, fuzzy, regex, and context-aware matching
- **Resilient to Changes**: Patches adapt to upstream modifications
- **Fast Performance**: Native Zig implementation (10-100x faster than JS)
- **Smart Fallbacks**: Multiple matchers with confidence scoring
- **Detailed Diagnostics**: Clear error messages and suggestions
- **Backup Support**: Automatic backups before modifications
- **Dry Run Mode**: Preview changes without modifying files

## Installation

### Build from Source

```bash
cd patcher
zig build -Doptimize=ReleaseFast
```

The binary will be created at `zig-out/bin/heimdall-patcher`.

### Install Zig (if needed)

```bash
# macOS
brew install zig

# Linux
wget https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
tar xf zig-linux-x86_64-0.11.0.tar.xz
export PATH=$PATH:$PWD/zig-linux-x86_64-0.11.0

# Windows
# Download from https://ziglang.org/download/
```

## Usage

### Apply Patches

```bash
# Apply all patches
heimdall-patcher apply

# Apply specific patch
heimdall-patcher apply patches/heimdall-branding.hpatch.json

# Dry run to preview changes
heimdall-patcher apply --dry-run

# Verbose output
heimdall-patcher apply --verbose

# No backup
heimdall-patcher apply --no-backup
```

### Verify Patches

```bash
# Verify all patches can be applied
heimdall-patcher verify

# Verify specific patch
heimdall-patcher verify patches/heimdall-branding.hpatch.json
```

### Other Commands

```bash
# List available patches
heimdall-patcher list

# Show patch details
heimdall-patcher info patches/heimdall-branding.hpatch.json

# Show help
heimdall-patcher help
```

## Patch Format

Patches use a JSON format (`.hpatch.json`) that describes changes with multiple matching strategies:

```json
{
  "version": "1.0",
  "name": "patch-name",
  "description": "Patch description",
  "patches": [
    {
      "id": "change-id",
      "files": ["path/to/file.ts"],
      "changes": [
        {
          "strategy": "replace",
          "matchers": [
            {"type": "exact", "pattern": "oldText"},
            {"type": "fuzzy", "pattern": "oldText", "confidence_threshold": 0.8}
          ],
          "replacement": "newText"
        }
      ]
    }
  ]
}
```

### Strategies

- `replace`: Replace matched text
- `inject_before`: Insert content before match
- `inject_after`: Insert content after match
- `wrap`: Wrap matched text
- `delete`: Remove matched text

### Matcher Types

- `exact`: Exact string matching
- `fuzzy`: Fuzzy matching with Levenshtein distance
- `regex`: Regular expression matching (coming soon)
- `context`: Context-aware matching (e.g., "last_import", "first_function")
- `ast`: AST-based matching (coming soon)

### Context Types

- `last_import`: After the last import statement
- `first_import`: Before the first import statement
- `last_function`: After the last function
- `class_start`: Inside a class body
- `file_start`: Beginning of file
- `file_end`: End of file

## Architecture

```
patcher/
├── src/
│   ├── main.zig              # CLI entry point
│   ├── patcher.zig           # Core patching engine
│   ├── patch_format.zig      # Patch format definitions
│   ├── matchers/             # Matching strategies
│   │   ├── exact.zig         # Exact string matching
│   │   ├── fuzzy.zig         # Fuzzy matching
│   │   ├── context.zig       # Context-aware matching
│   │   └── regex.zig         # Regex matching (TODO)
│   └── strategies/           # Application strategies
│       ├── replace.zig       # Text replacement
│       ├── inject.zig        # Code injection
│       └── wrap.zig          # Code wrapping
├── patches/                  # Patch files
└── tests/                    # Test suite
```

## How It Works

1. **Parse Patch File**: Load and validate the `.hpatch.json` file
2. **Find Target Files**: Locate files matching the patterns
3. **Apply Changes**: For each change:
   - Try primary matcher
   - Fall back to secondary matchers if needed
   - Apply the strategy (replace, inject, etc.)
4. **Validate**: Optionally run tests to verify changes
5. **Report**: Show success/failure with detailed diagnostics

## Advantages Over Traditional Patches

| Traditional Patches | Heimdall Patcher |
|-------------------|------------------|
| Line-based | Content-based |
| Fails on line changes | Adapts to changes |
| No fallback | Multiple strategies |
| Cryptic errors | Clear diagnostics |
| Slow (Git/JS) | Fast (Native Zig) |
| Fixed patterns | Fuzzy matching |

## Development

### Running Tests

```bash
zig build test
```

### Adding a New Matcher

1. Create `src/matchers/your_matcher.zig`
2. Implement the matcher interface
3. Add to `src/patcher.zig` runMatcher function
4. Update `src/patch_format.zig` MatcherType enum

### Adding a New Strategy

1. Create `src/strategies/your_strategy.zig`
2. Implement the strategy logic
3. Add to `src/patcher.zig` applyChange switch
4. Update `src/patch_format.zig` Strategy enum

## Roadmap

- [x] Core patching engine
- [x] Exact matching
- [x] Fuzzy matching
- [x] Context-aware matching
- [x] Basic strategies (replace, inject, delete)
- [ ] Regex matching
- [ ] AST-based matching for TypeScript/JavaScript
- [ ] Wrap strategy implementation
- [ ] Interactive patch creation
- [ ] Patch conversion from old format
- [ ] Rollback functionality
- [ ] Parallel patch application
- [ ] Web UI for patch management

## License

MIT