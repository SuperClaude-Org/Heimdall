/**
 * Heimdall Info Command
 * Custom command that shows Heimdall-specific information
 */

import type { Extension } from '../index';

export class HeimdallInfoCommand {
  static command = 'heimdall-info';
  static describe = 'Display Heimdall system information';
  static aliases = ['hinfo'];

  static builder(yargs: any) {
    return yargs
      .option('verbose', {
        alias: 'v',
        type: 'boolean',
        description: 'Show detailed information'
      });
  }

  static async handler(argv: any) {
    console.log(`
╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  
╠═╣║╣ ║║║║ ║║╠═╣║  ║  
╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝

Heimdall System Information
===========================

Version: ${process.env.HEIMDALL_VERSION || '0.1.0'}
Base: opencode v0.4.45
Architecture: Layered Modification System

Layers:
  1. Vendor (pristine opencode)
  2. Patches (git patches for modifications)  
  3. Extensions (new features)
  4. Overrides (complete file replacements)

Configuration:
  Config Path: ${process.env.HEIMDALL_CONFIG_PATH || '~/.heimdall'}
  Cache Path: ${process.env.HEIMDALL_CACHE_PATH || '~/.heimdall/cache'}
    `);

    if (argv.verbose) {
      console.log(`
Active Extensions:
  - heimdall-info (this command)
  - [Additional extensions will be listed here]

Active Patches:
  - 001-heimdall-branding.patch

Active Overrides:
  - [Override files will be listed here]
      `);
    }
  }
}

// Export as Extension
const extension: Extension = {
  name: 'heimdall-info',
  type: 'command',
  async init() {
    // Register with yargs when opencode initializes
    // This would be injected into the CLI setup
    console.debug('[HeimdallInfo] Command registered');
  }
};

export default extension;