#!/bin/bash
# Wrapper script for Cursor MCP that uses the release binary
# The release automatically detects stdio mode and starts accordingly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project directory
cd "$PROJECT_DIR" || exit 1

# Release binary path
RELEASE_BIN="${PROJECT_DIR}/_build/dev/rel/bpy_mcp/bin/bpy_mcp"

# If dev release doesn't exist, try prod
if [ ! -f "$RELEASE_BIN" ]; then
  RELEASE_BIN="${PROJECT_DIR}/_build/prod/rel/bpy_mcp/bin/bpy_mcp"
fi

# Stop any existing instances
if [ -f "$RELEASE_BIN" ]; then
  "$RELEASE_BIN" stop 2>/dev/null || true
  pkill -f "beam.*bpy_mcp" 2>/dev/null || true
  sleep 0.3
fi

# Use unique node name to avoid conflicts when multiple instances start
# Generate based on PID and timestamp
UNIQUE_ID="${$}-$(date +%s)"
export ELIXIR_ERL_OPTIONS="-sname bpy_mcp_${UNIQUE_ID}@localhost"

# Set MCP transport to stdio (release defaults to stdio, but explicit is better)
export MCP_TRANSPORT=stdio

# Start the release - it will automatically detect stdio mode and start accordingly
# The release binary handles stdio transport automatically
if [ -f "$RELEASE_BIN" ]; then
  exec "$RELEASE_BIN" start
else
  # Fallback to mix for development if release not built
  echo "Release not found, using mix. Run 'mix release' first." >&2
  exec mix mcp.stdio "$@"
fi

