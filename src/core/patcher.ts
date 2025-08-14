/**
 * Heimdall Runtime Patcher
 * Allows runtime modification of vendor code without changing files
 */

import { loader } from './loader';

export interface Patch {
  target: string;           // Module path to patch
  method?: string;          // Method/property to patch
  type: 'replace' | 'wrap' | 'extend' | 'inject';
  patch: Function;
}

export class RuntimePatcher {
  private patches: Map<string, Patch[]> = new Map();
  private applied: Set<string> = new Set();

  /**
   * Register a patch
   */
  register(patch: Patch) {
    const patches = this.patches.get(patch.target) || [];
    patches.push(patch);
    this.patches.set(patch.target, patches);
  }

  /**
   * Apply all registered patches
   */
  async applyAll() {
    for (const [target, patches] of this.patches) {
      if (!this.applied.has(target)) {
        await this.applyPatches(target, patches);
        this.applied.add(target);
      }
    }
  }

  /**
   * Apply patches to a specific module
   */
  private async applyPatches(target: string, patches: Patch[]) {
    try {
      const module = await loader.load(target);
      
      for (const patch of patches) {
        switch (patch.type) {
          case 'replace':
            this.applyReplace(module, patch);
            break;
          case 'wrap':
            this.applyWrap(module, patch);
            break;
          case 'extend':
            this.applyExtend(module, patch);
            break;
          case 'inject':
            this.applyInject(module, patch);
            break;
        }
      }
      
      console.debug(`[Patcher] Applied ${patches.length} patches to ${target}`);
    } catch (error) {
      console.error(`[Patcher] Failed to patch ${target}:`, error);
    }
  }

  /**
   * Replace a method/property entirely
   */
  private applyReplace(module: any, patch: Patch) {
    if (patch.method) {
      const original = module[patch.method];
      module[patch.method] = patch.patch(original);
      console.debug(`[Patcher] Replaced ${patch.method}`);
    }
  }

  /**
   * Wrap a method with before/after logic
   */
  private applyWrap(module: any, patch: Patch) {
    if (patch.method && typeof module[patch.method] === 'function') {
      const original = module[patch.method];
      module[patch.method] = function(...args: any[]) {
        return patch.patch(original, this, args);
      };
      console.debug(`[Patcher] Wrapped ${patch.method}`);
    }
  }

  /**
   * Extend a class or object
   */
  private applyExtend(module: any, patch: Patch) {
    const extensions = patch.patch();
    Object.assign(module, extensions);
    console.debug(`[Patcher] Extended module with ${Object.keys(extensions).length} properties`);
  }

  /**
   * Inject new functionality
   */
  private applyInject(module: any, patch: Patch) {
    patch.patch(module);
    console.debug(`[Patcher] Injected into module`);
  }
}

// Singleton patcher instance
export const patcher = new RuntimePatcher();

// Common patches for Heimdall branding
export const brandingPatches: Patch[] = [
  {
    target: 'vendor/opencode/packages/opencode/src/index.ts',
    method: 'scriptName',
    type: 'replace',
    patch: () => 'heimdall'
  },
  {
    target: 'vendor/opencode/packages/opencode/src/cli/ui.ts',
    method: 'displayBanner',
    type: 'wrap',
    patch: (original: Function, self: any, args: any[]) => {
      // Display Heimdall banner instead
      console.log(`
╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  
╠═╣║╣ ║║║║ ║║╠═╣║  ║  
╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝

Heimdall - AI-powered CLI assistant
      `);
      return undefined; // Don't call original
    }
  }
];

// Register default branding patches
brandingPatches.forEach(patch => patcher.register(patch));

export default patcher;