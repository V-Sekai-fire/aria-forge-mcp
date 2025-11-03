#!/bin/bash
# Wrapper script to stop any existing aria_forge instances before starting

RELEASE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RELEASE_BIN="$RELEASE_ROOT/bin/aria_forge"

# Stop any existing instances
if [ -f "$RELEASE_BIN" ]; then
  "$RELEASE_BIN" stop 2>/dev/null || true
  
  # Also kill any processes that might be hanging
  pkill -f "aria_forge" 2>/dev/null || true
  
  # Wait a moment for processes to fully stop
  sleep 0.5
fi

# Start the release
exec "$RELEASE_BIN" start "$@"

