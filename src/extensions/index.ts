/**
 * Heimdall Extensions System
 * Register and manage custom extensions to opencode
 */

export interface Extension {
  name: string;
  type: 'command' | 'provider' | 'tool' | 'middleware';
  init: () => Promise<void>;
}

export class ExtensionManager {
  private extensions: Map<string, Extension> = new Map();
  private initialized: Set<string> = new Set();

  /**
   * Register an extension
   */
  register(extension: Extension) {
    if (this.extensions.has(extension.name)) {
      console.warn(`[Extensions] Extension ${extension.name} already registered`);
      return;
    }
    
    this.extensions.set(extension.name, extension);
    console.debug(`[Extensions] Registered ${extension.type}: ${extension.name}`);
  }

  /**
   * Initialize all registered extensions
   */
  async initializeAll() {
    for (const [name, extension] of this.extensions) {
      if (!this.initialized.has(name)) {
        try {
          await extension.init();
          this.initialized.add(name);
          console.debug(`[Extensions] Initialized ${name}`);
        } catch (error) {
          console.error(`[Extensions] Failed to initialize ${name}:`, error);
        }
      }
    }
  }

  /**
   * Get extension by name
   */
  get(name: string): Extension | undefined {
    return this.extensions.get(name);
  }

  /**
   * List all extensions
   */
  list(): Extension[] {
    return Array.from(this.extensions.values());
  }
}

// Singleton instance
export const extensionManager = new ExtensionManager();

// Auto-discover and register extensions
export async function autoDiscoverExtensions() {
  const { promises: fs } = await import('fs');
  const path = await import('path');
  const { fileURLToPath } = await import('url');
  
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  
  const extensionDirs = ['commands', 'providers', 'tools'];
  
  for (const dir of extensionDirs) {
    const dirPath = path.join(__dirname, dir);
    
    try {
      const files = await fs.readdir(dirPath);
      
      for (const file of files) {
        if (file.endsWith('.ts') || file.endsWith('.js')) {
          const modulePath = path.join(dirPath, file);
          try {
            const module = await import(modulePath);
            
            // Check if module exports an extension
            if (module.default && typeof module.default === 'object' && 'name' in module.default) {
              extensionManager.register(module.default);
            }
          } catch (error) {
            console.error(`[Extensions] Failed to load ${file}:`, error);
          }
        }
      }
    } catch (error) {
      // Directory might not exist yet
      console.debug(`[Extensions] Directory ${dir} not found`);
    }
  }
}

export default extensionManager;