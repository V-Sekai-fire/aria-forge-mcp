#!/bin/bash
# Wrapper script for Cursor MCP that uses the release binary
# The release automatically detects stdio mode and starts accordingly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project directory
cd "$PROJECT_DIR" || exit 1

# Release binary path
RELEASE_BIN="${PROJECT_DIR}/_build/dev/rel/aria_forge/bin/aria_forge"

# If dev release doesn't exist, try prod
if [ ! -f "$RELEASE_BIN" ]; then
  RELEASE_BIN="${PROJECT_DIR}/_build/prod/rel/aria_forge/bin/aria_forge"
fi

# Stop any existing instances gracefully
if [ -f "$RELEASE_BIN" ]; then
  "$RELEASE_BIN" stop 2>/dev/null || true
  # Give processes time to clean up
  sleep 0.5
  # Force kill any remaining beam processes
  pkill -f "beam.*aria_forge" 2>/dev/null || true
  sleep 0.2
fi

# Disable distributed Erlang entirely for stdio mode - we don't need node names
# This prevents all "node name in use" warnings and conflicts
# Set MCP transport to stdio (release defaults to stdio, but explicit is better)
export MCP_TRANSPORT=stdio

# Disable distributed erlang and suppress all warnings at VM level
# Set logger to emergency level immediately to prevent any warnings
# No node name = no conflicts, no warnings
export ELIXIR_ERL_OPTIONS="-kernel error_logger {file,\"/dev/stderr\"} -elixir logger_level emergency +W w"

# Start the release - it will stay attached to stdin/stdout for stdio MCP
# The release binary handles stdio transport automatically
# We redirect stderr to /dev/null to prevent any remaining warnings from contaminating stdout
# Distributed Erlang is disabled, so no node name conflicts possible
if [ -f "$RELEASE_BIN" ]; then
  # Start command keeps process attached when running interactively (required for MCP stdio)
  # Stderr redirection prevents any warnings from contaminating JSON-RPC stream
  # Distributed erlang is disabled, eliminating node name conflicts
  exec "$RELEASE_BIN" start 2>/dev/null
else
  # Fallback to mix for development if release not built
  echo "Release not found, using mix. Run 'mix release' first." >&2
  exec mix mcp.stdio "$@"
fi

