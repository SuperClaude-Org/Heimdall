# 📊 Heimdall Logging Guide

## Command Line Options

### 1. **Enable Console Logging**
```bash
# Print logs to stderr (console output)
./bin/heimdall --print-logs

# This shows logs in real-time as the application runs
```

### 2. **Set Log Level**
```bash
# Available levels: DEBUG, INFO, WARN, ERROR

# Debug level (most verbose)
./bin/heimdall --log-level DEBUG

# Info level (default)
./bin/heimdall --log-level INFO

# Warning level
./bin/heimdall --log-level WARN

# Error level (least verbose)
./bin/heimdall --log-level ERROR
```

### 3. **Combine Options**
```bash
# Maximum verbosity: print to console with debug level
./bin/heimdall --print-logs --log-level DEBUG

# With specific commands
./bin/heimdall --print-logs --log-level DEBUG run "test"
./bin/heimdall --print-logs --log-level DEBUG auth status
./bin/heimdall --print-logs --log-level DEBUG serve
```

## Log File Locations

### Primary Log Files
```bash
# Current session log (always created)
~/.local/share/heimdall/log/dev.log

# Timestamped session logs
~/.local/share/heimdall/log/YYYY-MM-DDTHHMMSS.log
```

### View Logs
```bash
# Watch current log in real-time
tail -f ~/.local/share/heimdall/log/dev.log

# View last 100 lines
tail -n 100 ~/.local/share/heimdall/log/dev.log

# Search logs for errors
grep ERROR ~/.local/share/heimdall/log/dev.log

# Search logs for specific service
grep "service=provider" ~/.local/share/heimdall/log/dev.log
```

## Log Format

Logs follow this format:
```
LEVEL TIMESTAMP +MS service=SERVICE_NAME key=value message
```

Example:
```
INFO  2025-08-14T18:50:45 +47ms service=default version=dev args=[] heimdall
DEBUG 2025-08-14T18:50:45 +0ms service=tui model=claude-opus Selected model
ERROR 2025-08-14T18:50:45 +1ms service=default name=Error message=failed fatal
```

## Common Log Services

- `default` - Main application
- `app` - Application initialization
- `bus` - Event bus system
- `config` - Configuration loading
- `provider` - AI provider management
- `tui` - Terminal UI
- `server` - HTTP server
- `mcp` - Model Context Protocol servers
- `lsp` - Language Server Protocol
- `session` - Session management
- `format` - Code formatting

## Debugging Tips

### 1. **Enable Debug Logs for Troubleshooting**
```bash
# Start with maximum logging
./bin/heimdall --print-logs --log-level DEBUG 2>&1 | tee heimdall-debug.log
```

### 2. **Filter Logs by Service**
```bash
# See only MCP-related logs
./bin/heimdall --print-logs 2>&1 | grep "service=mcp"

# See only configuration logs
./bin/heimdall --print-logs 2>&1 | grep "service=config"
```

### 3. **Monitor Specific Events**
```bash
# Watch for errors
./bin/heimdall --print-logs 2>&1 | grep -E "ERROR|WARN"

# Watch for model selection
./bin/heimdall --print-logs 2>&1 | grep "model="
```

### 4. **Save Debug Session**
```bash
# Capture full debug output to file
./bin/heimdall --print-logs --log-level DEBUG 2>debug-session.log

# Run and save both output and logs
./bin/heimdall --print-logs --log-level DEBUG 2>&1 | tee full-session.log
```

## Environment Variables

You can also set logging via environment variables:
```bash
# Set log level
export HEIMDALL_LOG_LEVEL=DEBUG
./bin/heimdall

# Enable console logging
export HEIMDALL_PRINT_LOGS=true
./bin/heimdall
```

## Log Rotation

Logs are automatically managed:
- Current session: `dev.log` (overwritten each run)
- Historical logs: Timestamped files
- No automatic cleanup (manual deletion needed)

### Clean Old Logs
```bash
# Remove logs older than 7 days
find ~/.local/share/heimdall/log -name "*.log" -mtime +7 -delete

# Keep only last 10 log files
ls -t ~/.local/share/heimdall/log/*.log | tail -n +11 | xargs rm -f
```

## Common Issues in Logs

### 1. **Clipboard Warning**
```
ERROR Failed to initialize clipboard
```
**Solution**: Install `xclip` or `wl-clipboard`

### 2. **Provider Not Found**
```
ERROR service=provider providerID=xxx not found
```
**Solution**: Check API keys with `heimdall auth status`

### 3. **MCP Server Failed**
```
ERROR service=mcp failed to start server
```
**Solution**: Check MCP configuration in `~/.config/heimdall/heimdall.json`

## Performance Monitoring

### Check Response Times
```bash
# Look for duration in server logs
./bin/heimdall --print-logs 2>&1 | grep "duration="
```

### Monitor Memory Usage
```bash
# Run with system monitoring
/usr/bin/time -v ./bin/heimdall --print-logs
```

## Examples

### Debug Authentication Issues
```bash
./bin/heimdall --print-logs --log-level DEBUG auth status 2>&1 | grep -E "auth|provider"
```

### Debug MCP Tools
```bash
./bin/heimdall --print-logs --log-level DEBUG 2>&1 | grep -E "mcp|morphllm|serena"
```

### Debug Configuration Loading
```bash
./bin/heimdall --print-logs --log-level DEBUG 2>&1 | head -50
```

## Summary

- Use `--print-logs` to see logs in console
- Use `--log-level DEBUG` for maximum verbosity
- Logs always saved to `~/.local/share/heimdall/log/`
- Current session in `dev.log`
- Historical sessions in timestamped files
- Combine with `grep`, `tail`, `tee` for analysis