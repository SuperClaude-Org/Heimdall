#!/usr/bin/env bun
/**
 * Heimdall CLI - Main entry point
 * Wraps opencode functionality with Heimdall-specific configuration
 */

import "../../vendor/opencode/packages/opencode/src/index.ts";

// Re-export the main CLI execution
// The actual opencode CLI will handle all the commands
// We're just providing a branded entry point