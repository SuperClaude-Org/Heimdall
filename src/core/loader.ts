/**
 * Heimdall Module Loader
 * Implements a layered module resolution system
 */

import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { createRequire } from 'module';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export class HeimdallLoader {
  private rootDir: string;
  private overridesDir: string;
  private vendorDir: string;
  private extensionsDir: string;
  private require: NodeRequire;

  constructor() {
    this.rootDir = path.join(__dirname, '..', '..');
    this.overridesDir = path.join(this.rootDir, 'src', 'overrides');
    this.vendorDir = path.join(this.rootDir, 'vendor');
    this.extensionsDir = path.join(this.rootDir, 'src', 'extensions');
    this.require = createRequire(import.meta.url);
  }

  /**
   * Resolve module path with override support
   * Priority: overrides > vendor > node_modules
   */
  resolve(modulePath: string): string {
    // Check if this is a vendor module
    if (modulePath.includes('vendor/opencode')) {
      // Try override first
      const overridePath = modulePath.replace('vendor/', 'src/overrides/');
      const absoluteOverride = path.join(this.rootDir, overridePath);
      
      if (this.fileExists(absoluteOverride)) {
        console.debug(`[Loader] Using override: ${overridePath}`);
        return absoluteOverride;
      }
    }

    // Check for explicit override imports
    if (modulePath.startsWith('@heimdall/')) {
      const heimdallPath = modulePath.replace('@heimdall/', '');
      
      // Check overrides
      const overridePath = path.join(this.overridesDir, heimdallPath);
      if (this.fileExists(overridePath)) {
        return overridePath;
      }

      // Check extensions
      const extensionPath = path.join(this.extensionsDir, heimdallPath);
      if (this.fileExists(extensionPath)) {
        return extensionPath;
      }
    }

    // Default resolution
    return modulePath;
  }

  /**
   * Load a module with override support
   */
  async load(modulePath: string): Promise<any> {
    const resolvedPath = this.resolve(modulePath);
    
    try {
      // Use dynamic import for ES modules
      if (resolvedPath.endsWith('.ts') || resolvedPath.endsWith('.mjs')) {
        return await import(resolvedPath);
      }
      
      // Use require for CommonJS
      return this.require(resolvedPath);
    } catch (error) {
      console.error(`[Loader] Failed to load ${resolvedPath}:`, error);
      throw error;
    }
  }

  /**
   * Check if a file exists (with extension resolution)
   */
  private fileExists(filePath: string): boolean {
    // Check exact path
    if (fs.existsSync(filePath)) {
      return true;
    }

    // Try with extensions
    const extensions = ['.ts', '.js', '.mjs', '.json'];
    for (const ext of extensions) {
      if (fs.existsSync(filePath + ext)) {
        return true;
      }
    }

    // Check if it's a directory with index file
    if (fs.existsSync(filePath)) {
      const stats = fs.statSync(filePath);
      if (stats.isDirectory()) {
        for (const ext of extensions) {
          if (fs.existsSync(path.join(filePath, `index${ext}`))) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /**
   * Get all available overrides
   */
  listOverrides(): string[] {
    const overrides: string[] = [];
    
    if (!fs.existsSync(this.overridesDir)) {
      return overrides;
    }

    const walkDir = (dir: string, base: string = '') => {
      const files = fs.readdirSync(dir);
      
      for (const file of files) {
        const fullPath = path.join(dir, file);
        const relativePath = path.join(base, file);
        const stats = fs.statSync(fullPath);
        
        if (stats.isDirectory()) {
          walkDir(fullPath, relativePath);
        } else {
          overrides.push(relativePath);
        }
      }
    };

    walkDir(this.overridesDir);
    return overrides;
  }

  /**
   * Install the loader as a Bun plugin
   */
  asBunPlugin() {
    return {
      name: 'heimdall-loader',
      setup(build: any) {
        // Intercept imports
        build.onResolve({ filter: /.*/ }, (args: any) => {
          const resolved = this.resolve(args.path);
          if (resolved !== args.path) {
            return { path: resolved };
          }
        });
      }
    };
  }
}

// Singleton instance
export const loader = new HeimdallLoader();

// Export for use in other modules
export default loader;