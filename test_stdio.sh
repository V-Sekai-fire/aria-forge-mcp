#!/bin/bash
# Test script for bpy-mcp stdio server

set -e

echo "🧪 Testing bpy-mcp MCP stdio server" >&2
echo "====================================" >&2

# Test function to send JSON-RPC requests
test_request() {
    local request="$1"
    local description="$2"
    
    echo "$description" >&2
    echo "$request"
    sleep 0.5
}

# Create a temporary file for responses
RESPONSE_FILE=$(mktemp)
trap "rm -f $RESPONSE_FILE" EXIT

# Start the server as a background process, capturing stdout
cd /Users/ernest.lee/Developer/bpy-mcp

echo "Starting MCP stdio server..." >&2
(
    # Send initialize request
    test_request '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test-client","version":"1.0"}}}' "1. Initialize"
    
    # Send tools/list request
    test_request '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' "2. List tools"
    
    # Send a test tool call - reset_scene
    test_request '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"reset_scene","arguments":{}}}' "3. Call reset_scene"
    
    # Send get_scene_info
    test_request '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"get_scene_info","arguments":{}}}' "4. Get scene info"
    
    # Small delay before exit
    sleep 0.5
) | mix mcp.stdio 2>&1 | tee "$RESPONSE_FILE" &
SERVER_PID=$!

# Wait for server to finish (or timeout after 5 seconds)
wait $SERVER_PID 2>/dev/null || true

echo "" >&2
echo "✅ Test completed. Check responses above." >&2

