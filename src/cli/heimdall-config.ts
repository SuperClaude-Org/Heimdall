/**
 * Heimdall-specific configuration
 */

export const HEIMDALL_CONFIG = {
  name: 'heimdall',
  version: process.env.HEIMDALL_VERSION || '0.1.0',
  description: 'Heimdall - AI-powered CLI assistant',
  
  // Custom branding
  branding: {
    logo: `
╦ ╦╔═╗╦╔╦╗╔╦╗╔═╗╦  ╦  
╠═╣║╣ ║║║║ ║║╠═╣║  ║  
╩ ╩╚═╝╩╩ ╩═╩╝╩ ╩╩═╝╩═╝`,
    colors: {
      primary: '#FFD700',  // Gold
      secondary: '#4169E1', // Royal Blue
    }
  },
  
  // Override default opencode paths if needed
  paths: {
    config: process.env.HEIMDALL_CONFIG_PATH || '~/.heimdall',
    cache: process.env.HEIMDALL_CACHE_PATH || '~/.heimdall/cache',
  },
  
  // Custom defaults
  defaults: {
    model: process.env.HEIMDALL_DEFAULT_MODEL || 'claude-3-5-sonnet-latest',
    provider: process.env.HEIMDALL_DEFAULT_PROVIDER || 'anthropic',
  }
};

export function getHeimdallEnv() {
  return {
    OPENCODE_CONFIG_PATH: HEIMDALL_CONFIG.paths.config,
    OPENCODE_CACHE_PATH: HEIMDALL_CONFIG.paths.cache,
    OPENCODE_DEFAULT_MODEL: HEIMDALL_CONFIG.defaults.model,
    OPENCODE_DEFAULT_PROVIDER: HEIMDALL_CONFIG.defaults.provider,
  };
}