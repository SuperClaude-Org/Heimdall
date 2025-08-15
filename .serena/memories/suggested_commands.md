# Heimdall Development Commands

## Initial Setup
```bash
# Clone and setup (first time)
git clone <repo-url> heimdall
cd heimdall
bash setup.sh

# Manual setup steps
git clone https://github.com/opencodeco/opencode.git vendor/opencode
cd build && zig build && cd ..
./build/bin/heimdall-build
```

## Build Commands
```bash
# Full build pipeline
npm run build
./build/bin/heimdall-build

# Build with options
npm run build:dry      # Dry run (preview changes)
npm run build:verbose  # Verbose output
npm run build:force    # Force through errors
./build/bin/heimdall-build --auto-fix  # Auto-fix issues

# Zig-specific builds
npm run zig:build      # Build Zig binaries
npm run zig:test       # Run Zig tests
cd build && zig build -Doptimize=ReleaseFast
```

## Patch Management
```bash
# Apply patches
npm run patch:apply
./build/bin/heimdall-patcher apply

# Verify patches
npm run patch:verify
./build/bin/heimdall-patcher verify

# List patches
npm run patch:list
./build/bin/heimdall-patcher list

# Create new patch
npm run patch:create
./build/bin/heimdall-patcher create

# Patch info
./build/bin/heimdall-patcher info <patch-file>
```

## Testing
```bash
# Run all tests
npm test

# Specific test suites
npm run test:unit
npm run test:integration
npm run test:patch

# Complete setup test
bash test_complete_setup.sh

# Test binaries
./build/bin/heimdall-build --help
./build/bin/heimdall-patcher --help
```

## Development
```bash
# Update vendor from upstream
git -C vendor/opencode pull origin main

# Clean build artifacts
npm run clean
rm -rf .build .zig-cache dist node_modules

# Install dependencies
npm install
cd vendor/opencode && bun install
```

## Git Commands
```bash
# Standard git workflow
git status
git add .
git commit -m "message"
git push origin main
git pull origin main

# Branch management
git checkout -b feature-branch
git merge main
```

## System Utilities (Linux)
```bash
# File operations
ls -la              # List files with details
cd <directory>      # Change directory
pwd                 # Print working directory
mkdir -p <dir>      # Create directory
rm -rf <path>       # Remove files/directories
cp -r <src> <dst>   # Copy recursively
mv <src> <dst>      # Move/rename

# Search and find
find . -name "*.zig"           # Find files by name
grep -r "pattern" .            # Search in files
rg "pattern"                   # Ripgrep (faster search)

# Process management
ps aux              # List processes
kill <pid>          # Kill process
htop                # Interactive process viewer

# File permissions
chmod +x <file>     # Make executable
chown user:group    # Change ownership
```

## Running Heimdall
```bash
# After build completion
./bin/heimdall --help
./bin/heimdall --version
./bin/heimdall models
./bin/heimdall auth status
./bin/heimdall run "command"
```