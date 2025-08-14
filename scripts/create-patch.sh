#!/bin/bash
# Create comprehensive branding patch
cd /home/anton/opencode-heimdall
git diff vendor/ > patches/001-heimdall-complete-branding.patch
echo "Patch created successfully"
ls -la patches/001-heimdall-complete-branding.patch