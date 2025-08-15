#!/usr/bin/env node

/**
 * Pattern-Based Branding System for Heimdall
 * 
 * This script applies branding changes using search-and-replace patterns
 * instead of traditional line-based patches, making it more resilient to
 * upstream changes.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PATTERNS_FILE = path.join(__dirname, 'branding-patterns.json');
const ROOT_DIR = path.join(__dirname, '..');

class BrandingApplicator {
  constructor() {
    this.patterns = this.loadPatterns();
    this.stats = {
      filesProcessed: 0,
      replacementsMade: 0,
      errors: []
    };
  }

  loadPatterns() {
    try {
      const content = fs.readFileSync(PATTERNS_FILE, 'utf8');
      return JSON.parse(content);
    } catch (error) {
      console.error(`Failed to load patterns from ${PATTERNS_FILE}:`, error.message);
      process.exit(1);
    }
  }

  /**
   * Apply a single replacement pattern to content
   */
  applyPattern(content, pattern) {
    let newContent = content;
    let replacements = 0;

    if (pattern.search_multiline && pattern.replace_multiline) {
      // Handle multiline patterns
      const regex = new RegExp(
        pattern.search_multiline.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
        pattern.global ? 'g' : ''
      );
      const before = newContent;
      newContent = newContent.replace(regex, pattern.replace_multiline);
      if (before !== newContent) replacements++;
    } else if (pattern.search && pattern.replace) {
      // Handle simple patterns
      if (pattern.context) {
        // Context-aware replacement
        // This is a simplified version - could be enhanced with AST parsing
        const contextRegex = new RegExp(pattern.context);
        const lines = newContent.split('\n');
        let inContext = false;
        let contextDepth = 0;
        
        for (let i = 0; i < lines.length; i++) {
          if (contextRegex.test(lines[i])) {
            inContext = true;
            contextDepth = 0;
          }
          
          if (inContext) {
            const before = lines[i];
            lines[i] = lines[i].replace(pattern.search, pattern.replace);
            if (before !== lines[i]) replacements++;
            
            // Simple context tracking (could be improved)
            contextDepth++;
            if (contextDepth > 10 || lines[i].includes('}')) {
              inContext = false;
            }
          }
        }
        newContent = lines.join('\n');
      } else {
        // Global or single replacement
        const regex = pattern.global 
          ? new RegExp(pattern.search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g')
          : pattern.search;
        const before = newContent;
        newContent = newContent.replace(regex, pattern.replace);
        if (before !== newContent) {
          replacements = pattern.global 
            ? (newContent.match(new RegExp(pattern.replace.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g')) || []).length
            : 1;
        }
      }
    }

    return { content: newContent, replacements };
  }

  /**
   * Process a single file with all applicable patterns
   */
  processFile(filePath, patterns) {
    const fullPath = path.join(ROOT_DIR, filePath);
    
    if (!fs.existsSync(fullPath)) {
      console.warn(`  ⚠ File not found: ${filePath}`);
      return 0;
    }

    let content = fs.readFileSync(fullPath, 'utf8');
    const originalContent = content;
    let totalReplacements = 0;

    for (const pattern of patterns) {
      const result = this.applyPattern(content, pattern);
      content = result.content;
      totalReplacements += result.replacements;
      
      if (result.replacements > 0) {
        console.log(`    ✓ Applied pattern: ${pattern.search || pattern.search_multiline?.substring(0, 30)}... (${result.replacements} replacements)`);
      }
    }

    if (content !== originalContent) {
      // Backup original if configured
      if (this.patterns.config?.backup) {
        const backupPath = fullPath + '.bak';
        if (!fs.existsSync(backupPath)) {
          fs.writeFileSync(backupPath, originalContent);
        }
      }
      
      // Write modified content
      fs.writeFileSync(fullPath, content);
      console.log(`  ✓ Updated ${filePath} (${totalReplacements} total replacements)`);
    } else {
      console.log(`  - No changes needed for ${filePath}`);
    }

    return totalReplacements;
  }

  /**
   * Apply all branding patterns
   */
  apply() {
    console.log('╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  ');
    console.log('╠═╣║╣ ║║║║ ║║╠═╣║  ║  ');
    console.log('╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝');
    console.log('=== Applying Branding Patterns ===\n');

    for (const replacement of this.patterns.replacements) {
      console.log(`\n▶ ${replacement.name}`);
      
      for (const file of replacement.files) {
        try {
          const replacements = this.processFile(file, replacement.patterns);
          this.stats.filesProcessed++;
          this.stats.replacementsMade += replacements;
        } catch (error) {
          console.error(`  ✗ Error processing ${file}: ${error.message}`);
          this.stats.errors.push({ file, error: error.message });
          
          if (this.patterns.config?.stop_on_error) {
            console.error('\nStopping due to error (stop_on_error is true)');
            process.exit(1);
          }
        }
      }
    }

    // Print summary
    console.log('\n' + '═'.repeat(50));
    console.log('Summary:');
    console.log(`  Files processed: ${this.stats.filesProcessed}`);
    console.log(`  Replacements made: ${this.stats.replacementsMade}`);
    if (this.stats.errors.length > 0) {
      console.log(`  Errors: ${this.stats.errors.length}`);
      this.stats.errors.forEach(e => {
        console.log(`    - ${e.file}: ${e.error}`);
      });
    }
    console.log('═'.repeat(50));

    // Create a git patch if configured
    if (this.patterns.config?.create_patch_after && this.stats.replacementsMade > 0) {
      this.createPatch();
    }
  }

  /**
   * Create a git patch from the changes
   */
  createPatch() {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
      const patchFile = path.join(ROOT_DIR, 'patches', `pattern-based-branding-${timestamp}.patch`);
      
      const { execSync } = await import('child_process');
      execSync(`cd "${ROOT_DIR}" && git diff vendor/ > "${patchFile}"`, { stdio: 'pipe' });
      
      const patchSize = fs.statSync(patchFile).size;
      if (patchSize > 0) {
        console.log(`\n✓ Created patch file: ${path.basename(patchFile)}`);
      } else {
        fs.unlinkSync(patchFile);
        console.log('\n- No changes to create patch from');
      }
    } catch (error) {
      console.warn('\n⚠ Could not create patch file:', error.message);
    }
  }

  /**
   * Revert all branding changes
   */
  revert() {
    console.log('╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  ');
    console.log('╠═╣║╣ ║║║║ ║║╠═╣║  ║  ');
    console.log('╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝');
    console.log('=== Reverting Branding ===\n');

    let restoredCount = 0;
    
    // Collect all unique files
    const allFiles = new Set();
    for (const replacement of this.patterns.replacements) {
      replacement.files.forEach(file => allFiles.add(file));
    }

    // Restore from backups
    for (const file of allFiles) {
      const fullPath = path.join(ROOT_DIR, file);
      const backupPath = fullPath + '.bak';
      
      if (fs.existsSync(backupPath)) {
        const backup = fs.readFileSync(backupPath, 'utf8');
        fs.writeFileSync(fullPath, backup);
        console.log(`  ✓ Restored ${file} from backup`);
        restoredCount++;
      } else {
        console.log(`  - No backup found for ${file}`);
      }
    }

    console.log(`\n✓ Restored ${restoredCount} files`);
  }

  /**
   * Validate patterns without applying them
   */
  validate() {
    console.log('=== Validating Branding Patterns ===\n');
    
    let issues = 0;
    
    for (const replacement of this.patterns.replacements) {
      console.log(`▶ ${replacement.name}`);
      
      for (const file of replacement.files) {
        const fullPath = path.join(ROOT_DIR, file);
        if (!fs.existsSync(fullPath)) {
          console.log(`  ✗ File not found: ${file}`);
          issues++;
        } else {
          console.log(`  ✓ File exists: ${file}`);
        }
      }
      
      for (const pattern of replacement.patterns) {
        if (!pattern.search && !pattern.search_multiline) {
          console.log(`  ✗ Pattern missing search field`);
          issues++;
        }
        if (!pattern.replace && !pattern.replace_multiline) {
          console.log(`  ✗ Pattern missing replace field`);
          issues++;
        }
      }
    }
    
    if (issues === 0) {
      console.log('\n✓ All patterns valid');
    } else {
      console.log(`\n✗ Found ${issues} issues`);
    }
    
    return issues === 0;
  }
}

// CLI handling
const args = process.argv.slice(2);
const command = args[0] || 'apply';

const applicator = new BrandingApplicator();

switch (command) {
  case 'apply':
    applicator.apply();
    break;
  case 'revert':
    applicator.revert();
    break;
  case 'validate':
    process.exit(applicator.validate() ? 0 : 1);
    break;
  case 'help':
    console.log(`
Usage: node apply-branding.js [command]

Commands:
  apply     Apply all branding patterns (default)
  revert    Revert branding using backup files
  validate  Validate patterns without applying
  help      Show this help message

Configuration is read from: branding-patterns.json
`);
    break;
  default:
    console.error(`Unknown command: ${command}`);
    console.log('Use "help" to see available commands');
    process.exit(1);
}