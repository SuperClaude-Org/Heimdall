#!/usr/bin/env node

/**
 * Rebranding script for Heimdall
 * This script performs selective rebranding of opencode to Heimdall
 * focusing on user-facing elements while keeping internal references intact
 * to ease future merges from upstream.
 */

import fs from 'fs';
import path from 'path';
import { glob } from 'glob';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Define replacement patterns
const replacements = [
  // User-facing strings
  { pattern: /opencode CLI/g, replacement: 'Heimdall CLI' },
  { pattern: /opencode/g, replacement: 'heimdall', files: ['**/bin/*', '**/package.json'] },
  { pattern: /OPENCODE/g, replacement: 'HEIMDALL', files: ['**/*.md', '**/bin/*'] },
  { pattern: /OpenCode/g, replacement: 'Heimdall', files: ['**/*.md', '**/package.json'] },
  
  // CLI commands - only in specific files
  { pattern: /"opencode"/g, replacement: '"heimdall"', files: ['**/package.json', '**/cli.ts', '**/index.ts'] },
  
  // Package names
  { pattern: /@opencode\//g, replacement: '@heimdall/', files: ['**/package.json'] },
  { pattern: /name": "opencode"/g, replacement: 'name": "heimdall"', files: ['**/package.json'] },
];

// Paths to rebrand (relative to vendor/opencode)
const targetPaths = [
  'packages/opencode/package.json',
  'packages/opencode/bin/*',
  'packages/opencode/src/cli.ts',
  'packages/opencode/src/index.ts',
  'packages/opencode/README.md',
  'package.json',
  'README.md',
];

// Files to skip (keep original)
const skipFiles = [
  '**/node_modules/**',
  '**/.git/**',
  '**/dist/**',
  '**/build/**',
];

function shouldSkipFile(filePath) {
  return skipFiles.some(pattern => {
    const regex = new RegExp(pattern.replace(/\*/g, '.*'));
    return regex.test(filePath);
  });
}

function processFile(filePath, dryRun = false) {
  if (shouldSkipFile(filePath)) {
    return false;
  }

  try {
    let content = fs.readFileSync(filePath, 'utf8');
    let modified = false;
    let originalContent = content;

    // Apply replacements based on file patterns
    replacements.forEach(({ pattern, replacement, files }) => {
      // If files array is specified, check if current file matches
      if (files) {
        const matches = files.some(filePattern => {
          const regex = new RegExp(filePattern.replace(/\*/g, '.*'));
          return regex.test(filePath);
        });
        if (!matches) return;
      }

      if (pattern.test(content)) {
        content = content.replace(pattern, replacement);
        modified = true;
      }
    });

    if (modified) {
      if (dryRun) {
        console.log(`Would modify: ${filePath}`);
        // Show a diff preview
        const changes = content.split('\n').filter((line, i) => 
          line !== originalContent.split('\n')[i]
        ).length;
        console.log(`  Changes: ${changes} lines`);
      } else {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`✓ Modified: ${filePath}`);
      }
      return true;
    }
    return false;
  } catch (error) {
    console.error(`Error processing ${filePath}:`, error.message);
    return false;
  }
}

function rebrand(dryRun = false) {
  console.log('Starting Heimdall rebranding process...');
  if (dryRun) {
    console.log('(DRY RUN - no files will be modified)');
  }
  console.log('');

  const vendorPath = path.join(__dirname, '..', 'vendor', 'opencode');
  let totalModified = 0;

  targetPaths.forEach(targetPattern => {
    const fullPattern = path.join(vendorPath, targetPattern);
    const files = glob.sync(fullPattern, { nodir: true });
    
    files.forEach(file => {
      if (processFile(file, dryRun)) {
        totalModified++;
      }
    });
  });

  console.log('');
  console.log(`Rebranding complete: ${totalModified} files ${dryRun ? 'would be' : ''} modified`);
}

// Parse command line arguments
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');

// Run the rebranding
rebrand(dryRun);