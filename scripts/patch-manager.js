#!/usr/bin/env node

/**
 * Patch Manager for Heimdall
 * Manages git patches for vendor modifications
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PATCHES_DIR = path.join(__dirname, '..', 'patches');
const VENDOR_DIR = path.join(__dirname, '..', 'vendor', 'opencode');

// List of patches in order
const PATCHES = [
  '001-heimdall-complete-branding.patch',
  '002-enhanced-agents-discovery.patch',
  '003-heimdall-ascii-art-branding.patch'
];

class PatchManager {
  constructor() {
    this.patches = this.loadPatches();
  }

  loadPatches() {
    if (!fs.existsSync(PATCHES_DIR)) {
      fs.mkdirSync(PATCHES_DIR, { recursive: true });
      return [];
    }

    return fs.readdirSync(PATCHES_DIR)
      .filter(f => f.endsWith('.patch'))
      .sort()
      .map(f => path.join(PATCHES_DIR, f));
  }

  apply(dryRun = false) {
    console.log(`Applying ${this.patches.length} patches...`);
    const results = [];

    for (const patchFile of this.patches) {
      const patchName = path.basename(patchFile);
      
      try {
        // Check if patch can be applied
        execSync(`git apply --check ${patchFile}`, { 
          cwd: path.join(__dirname, '..'),
          stdio: 'pipe' 
        });

        if (!dryRun) {
          // Apply the patch
          execSync(`git apply ${patchFile}`, { 
            cwd: path.join(__dirname, '..'),
            stdio: 'pipe' 
          });
        }

        console.log(`✓ ${dryRun ? 'Can apply' : 'Applied'}: ${patchName}`);
        results.push({ patch: patchName, status: 'success' });
      } catch (error) {
        console.log(`✗ Failed: ${patchName}`);
        if (error.stderr) {
          console.log(`  Reason: ${error.stderr.toString()}`);
        }
        results.push({ patch: patchName, status: 'failed', error: error.message });
      }
    }

    return results;
  }

  revert() {
    console.log('Reverting all patches...');
    
    // Reverse order for reverting
    const reversedPatches = [...this.patches].reverse();
    
    for (const patchFile of reversedPatches) {
      const patchName = path.basename(patchFile);
      
      try {
        execSync(`git apply --reverse ${patchFile}`, { 
          cwd: path.join(__dirname, '..'),
          stdio: 'pipe' 
        });
        console.log(`✓ Reverted: ${patchName}`);
      } catch (error) {
        console.log(`✗ Failed to revert: ${patchName}`);
      }
    }
  }

  create(name, description) {
    // Check for uncommitted changes in vendor
    try {
      const status = execSync('git status --porcelain vendor/', { 
        cwd: path.join(__dirname, '..'),
        encoding: 'utf8' 
      });

      if (!status.trim()) {
        console.log('No changes in vendor/ to create patch from');
        return;
      }

      // Generate patch filename
      const timestamp = new Date().toISOString().split('T')[0].replace(/-/g, '');
      const patchNumber = String(this.patches.length + 1).padStart(3, '0');
      const safeName = name.toLowerCase().replace(/[^a-z0-9-]/g, '-');
      const patchFile = path.join(PATCHES_DIR, `${patchNumber}-${safeName}.patch`);

      // Create the patch
      const patchContent = execSync('git diff vendor/', { 
        cwd: path.join(__dirname, '..'),
        encoding: 'utf8' 
      });

      // Add description header
      const header = `# Heimdall Patch: ${name}
# Description: ${description}
# Created: ${new Date().toISOString()}
# 
`;
      
      fs.writeFileSync(patchFile, header + patchContent);
      console.log(`✓ Created patch: ${path.basename(patchFile)}`);

      // Optionally revert the changes
      console.log('\nRevert vendor changes? (y/n)');
      // In a real implementation, we'd wait for user input
      
    } catch (error) {
      console.error('Error creating patch:', error.message);
    }
  }

  list() {
    console.log('Available patches:');
    this.patches.forEach(patchFile => {
      const name = path.basename(patchFile);
      const content = fs.readFileSync(patchFile, 'utf8');
      const description = content.match(/# Description: (.+)/)?.[1] || 'No description';
      console.log(`  ${name}: ${description}`);
    });
  }

  verify() {
    console.log('Verifying patches...');
    const results = this.apply(true);
    
    const failed = results.filter(r => r.status === 'failed');
    if (failed.length > 0) {
      console.log(`\n⚠️  ${failed.length} patches need attention`);
      return false;
    }
    
    console.log('\n✓ All patches can be applied cleanly');
    return true;
  }
}

// CLI interface
const command = process.argv[2];
const manager = new PatchManager();

switch (command) {
  case 'apply':
    manager.apply();
    break;
  case 'revert':
    manager.revert();
    break;
  case 'create':
    const name = process.argv[3] || 'unnamed';
    const description = process.argv[4] || 'No description';
    manager.create(name, description);
    break;
  case 'list':
    manager.list();
    break;
  case 'verify':
    manager.verify();
    break;
  default:
    console.log(`
Heimdall Patch Manager

Usage:
  patch-manager apply   - Apply all patches to vendor
  patch-manager revert  - Revert all patches from vendor
  patch-manager create <name> <description> - Create patch from current vendor changes
  patch-manager list    - List all available patches
  patch-manager verify  - Check if patches can be applied cleanly
    `);
}

export { PatchManager };