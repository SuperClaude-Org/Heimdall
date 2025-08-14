/**
 * Heimdall Dependency Injector
 * Inject custom functionality into opencode modules
 */

import { loader } from './loader';
import { extensionManager } from '../extensions';

export interface Injectable {
  target: string;      // Module to inject into
  property: string;    // Property/method name
  value: any;         // Value to inject
  type: 'property' | 'method' | 'class';
}

export class DependencyInjector {
  private injections: Map<string, Injectable[]> = new Map();
  private injected: Set<string> = new Set();

  /**
   * Register an injection
   */
  register(injection: Injectable) {
    const injections = this.injections.get(injection.target) || [];
    injections.push(injection);
    this.injections.set(injection.target, injections);
  }

  /**
   * Apply all injections
   */
  async applyAll() {
    for (const [target, injections] of this.injections) {
      if (!this.injected.has(target)) {
        await this.applyInjections(target, injections);
        this.injected.add(target);
      }
    }
  }

  /**
   * Apply injections to a specific module
   */
  private async applyInjections(target: string, injections: Injectable[]) {
    try {
      const module = await loader.load(target);
      
      for (const injection of injections) {
        switch (injection.type) {
          case 'property':
            module[injection.property] = injection.value;
            console.debug(`[Injector] Injected property ${injection.property} into ${target}`);
            break;
            
          case 'method':
            if (typeof injection.value === 'function') {
              module[injection.property] = injection.value;
              console.debug(`[Injector] Injected method ${injection.property} into ${target}`);
            }
            break;
            
          case 'class':
            if (typeof injection.value === 'function') {
              module[injection.property] = injection.value;
              console.debug(`[Injector] Injected class ${injection.property} into ${target}`);
            }
            break;
        }
      }
    } catch (error) {
      console.error(`[Injector] Failed to inject into ${target}:`, error);
    }
  }

  /**
   * Inject Heimdall commands into opencode CLI
   */
  async injectCommands(yargsInstance: any) {
    const commands = extensionManager.list()
      .filter(ext => ext.type === 'command');
    
    for (const cmdExtension of commands) {
      try {
        // Load the command module
        const cmdModule = await import(`../extensions/commands/${cmdExtension.name}.ts`);
        const CommandClass = cmdModule.default || cmdModule[Object.keys(cmdModule)[0]];
        
        if (CommandClass && CommandClass.command) {
          yargsInstance.command(
            CommandClass.command,
            CommandClass.describe || '',
            CommandClass.builder || {},
            CommandClass.handler || (() => {})
          );
          console.debug(`[Injector] Injected command: ${CommandClass.command}`);
        }
      } catch (error) {
        console.error(`[Injector] Failed to inject command ${cmdExtension.name}:`, error);
      }
    }
  }

  /**
   * Inject Heimdall providers
   */
  async injectProviders() {
    const providers = extensionManager.list()
      .filter(ext => ext.type === 'provider');
    
    for (const providerExt of providers) {
      // Implementation would depend on opencode's provider system
      console.debug(`[Injector] Would inject provider: ${providerExt.name}`);
    }
  }

  /**
   * Inject Heimdall tools
   */
  async injectTools() {
    const tools = extensionManager.list()
      .filter(ext => ext.type === 'tool');
    
    for (const toolExt of tools) {
      // Implementation would depend on opencode's tool system
      console.debug(`[Injector] Would inject tool: ${toolExt.name}`);
    }
  }
}

// Singleton instance
export const injector = new DependencyInjector();

// Register default injections for Heimdall branding
injector.register({
  target: 'vendor/opencode/packages/opencode/src/installation.ts',
  property: 'VERSION',
  value: process.env.HEIMDALL_VERSION || '0.1.0',
  type: 'property'
});

injector.register({
  target: 'vendor/opencode/packages/opencode/src/installation.ts',
  property: 'NAME',
  value: 'Heimdall',
  type: 'property'
});

export default injector;