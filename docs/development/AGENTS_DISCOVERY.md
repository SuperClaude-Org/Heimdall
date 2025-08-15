# 🔍 AGENTS.md Discovery & Injection System

## Overview

The Heimdall/OpenCode CLI has a sophisticated system for discovering and injecting custom agent configurations and instructions. This document explains how it works internally.

## Components Involved

### 1. **Config Module** (`src/config/config.ts`)
- **Primary Role**: Discovers and loads agent configuration files
- **Key Functions**:
  - Searches for `agent/*.md` files in multiple locations
  - Parses markdown files with YAML frontmatter
  - Merges configurations into the global config

### 2. **System Prompt Module** (`src/session/system.ts`)
- **Primary Role**: Discovers and injects AGENTS.md into system prompts
- **Key Functions**:
  - Searches for AGENTS.md, CLAUDE.md, CONTEXT.md files
  - Loads custom instructions from config
  - Injects content into AI system prompts

### 3. **Filesystem Utilities** (`src/util/filesystem.ts`)
- **Primary Role**: Provides file discovery utilities
- **Key Functions**:
  - `globUp()`: Searches up directory tree with glob patterns
  - `findUp()`: Finds specific files up the directory tree

### 4. **Global Paths** (`src/global/index.ts`)
- **Primary Role**: Defines standard configuration directories
- **Key Paths**:
  - `~/.config/heimdall/` - Global configuration directory
  - `~/.local/share/heimdall/` - Data directory
  - `~/.local/state/heimdall/` - State directory

## Discovery Process

### Agent Configuration Discovery (`agent/*.md`)

The system searches for agent configuration files in this order:

1. **Global Config Directory**:
   ```
   ~/.config/heimdall/agent/*.md
   ```

2. **Project Directory** (searches up from CWD):
   ```
   .heimdall/agent/*.md
   ```

3. **Loading Process**:
   ```typescript
   // From config.ts
   const markdownAgents = [
     ...(await Filesystem.globUp("agent/*.md", Global.Path.config, Global.Path.config)),
     ...(await Filesystem.globUp(".heimdall/agent/*.md", app.path.cwd, app.path.root)),
   ]
   ```

4. **Parsing**:
   - Uses `gray-matter` to parse YAML frontmatter
   - Frontmatter becomes agent configuration
   - Markdown body becomes the agent prompt

### AGENTS.md Discovery (System Instructions)

The system searches for instruction files in this priority order:

1. **Local Project Files** (stops at first match):
   - `AGENTS.md` (preferred)
   - `CLAUDE.md` (legacy)
   - `CONTEXT.md` (deprecated)
   
   Searches from current directory up to git root.

2. **Global Files** (stops at first match):
   - `~/.config/heimdall/AGENTS.md`
   - `~/.claude/CLAUDE.md` (legacy)

3. **Config Instructions**:
   - Files/patterns specified in `heimdall.json` → `instructions[]`
   - Supports absolute paths, relative paths, and globs
   - Can use `~/` for home directory

## File Format

### Agent Configuration Files (`agent/*.md`)

```markdown
---
# YAML frontmatter
temperature: 0.7
tools:
  write: false
  edit: false
  bash: true
description: "Agent for code review"
model: "anthropic/claude-3-5-sonnet"
---

# Markdown body becomes the prompt
You are a code review specialist. Focus on:
- Security vulnerabilities
- Performance issues
- Best practices
```

### AGENTS.md Format

Plain markdown file with instructions:

```markdown
# Project Guidelines

This is a TypeScript project using:
- Bun runtime
- Hono framework
- Model Context Protocol

## Coding Standards
- Use functional programming patterns
- Prefer immutability
- Add comprehensive error handling
```

## Injection Process

### 1. **Agent Configuration Injection**

Loaded agents are merged into the config and become available as:
- Selectable agents in the TUI (Tab/Shift+Tab)
- Callable via `--agent` flag
- Subagents for the Task tool

### 2. **System Prompt Injection**

AGENTS.md content is injected into:
- Initial system prompt for new sessions
- Context for all AI interactions
- Loaded in this order:
  1. Provider-specific prompts (anthropic.txt, etc.)
  2. Environment information
  3. **Custom instructions (AGENTS.md)**
  4. Agent-specific prompts

## Search Algorithm

### globUp() Function
```typescript
async function globUp(pattern: string, start: string, stop?: string) {
  // Starts at 'start' directory
  // Searches for files matching 'pattern'
  // Moves up directory tree until 'stop' or root
  // Returns all matches found
}
```

### findUp() Function
```typescript
async function findUp(target: string, start: string, stop?: string) {
  // Similar to globUp but for exact filename
  // Returns array of all matches found
}
```

## Configuration Priority

1. **Built-in defaults** (lowest priority)
2. **Global config** (`~/.config/heimdall/`)
3. **Project config** (`.heimdall/` in project)
4. **Command-line flags** (highest priority)

## File Locations Summary

### Global Locations
- `~/.config/heimdall/AGENTS.md` - Global instructions
- `~/.config/heimdall/agent/*.md` - Global agent configs
- `~/.config/heimdall/heimdall.json` - Global configuration
- `~/.config/heimdall/mode/*.md` - Mode configurations (deprecated)

### Project Locations
- `AGENTS.md` - Project instructions (root or any parent)
- `.heimdall/agent/*.md` - Project agent configs
- `.heimdall/mode/*.md` - Project mode configs (deprecated)
- `heimdall.json` - Project configuration

## Key Code Paths

### Agent Loading
```
config.ts:45-67 - Agent markdown file discovery and parsing
config.ts:182-200 - Agent configuration schema
agent.ts:46-100 - Agent initialization and defaults
```

### Instruction Loading
```
system.ts:55-108 - AGENTS.md discovery and loading
system.ts:57-62 - Local rule files list
system.ts:63-66 - Global rule files list
system.ts:68-108 - Custom instruction loading logic
```

## Customization Points

### 1. **Add Global Agents**
Place `.md` files in `~/.config/heimdall/agent/`

### 2. **Add Project Agents**
Place `.md` files in `.heimdall/agent/` within project

### 3. **Add Global Instructions**
Create `~/.config/heimdall/AGENTS.md`

### 4. **Add Project Instructions**
Create `AGENTS.md` in project root

### 5. **Configure in heimdall.json**
```json
{
  "instructions": [
    "~/my-rules/*.md",
    "./project-rules.md",
    "/absolute/path/to/rules.md"
  ]
}
```

## Mode vs Agent

- **Modes** (deprecated): Old system, migrated to agents
- **Agents**: Current system with three types:
  - `primary`: Main agents selectable with Tab
  - `subagent`: Available to Task tool
  - `all`: Available everywhere

## Debugging

### Check What's Loaded
```bash
# See loaded agents
./bin/heimdall agent list

# Check config loading with debug logs
./bin/heimdall --print-logs --log-level DEBUG 2>&1 | grep -E "config|agent"

# See what files are being searched
strace -e openat ./bin/heimdall 2>&1 | grep -E "AGENTS|agent"
```

### Common Issues

1. **AGENTS.md not loading**:
   - Check file exists in searched locations
   - Ensure no syntax errors in markdown
   - Verify file permissions

2. **Agent not appearing**:
   - Check YAML frontmatter syntax
   - Verify agent name is unique
   - Check for `disable: true` in config

3. **Instructions not applying**:
   - Check load order (project overrides global)
   - Verify file path in config
   - Check glob patterns match files