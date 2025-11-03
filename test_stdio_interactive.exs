#!/usr/bin/env elixir

# Interactive test script for MCP stdio server
# Usage: elixir test_stdio_interactive.exs

Mix.install([])

defmodule TestStdio do
  def run do
    IO.puts(:stderr, "🧪 Interactive MCP stdio test")
    IO.puts(:stderr, "Press Ctrl+D to exit")
    IO.puts(:stderr, "")

    # Start the MCP server process
    port = Port.open({:spawn, "mix mcp.stdio"}, [:binary, :exit_status])

    # Send initialize
    send_request(port, %{
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: %{
        protocolVersion: "2025-03-26",
        capabilities: %{},
        clientInfo: %{name: "test-client", version: "1.0"}
      }
    })

    # Send tools/list
    send_request(port, %{
      jsonrpc: "2.0",
      id: 2,
      method: "tools/list",
      params: %{}
    })

    # Send reset_scene
    send_request(port, %{
      jsonrpc: "2.0",
      id: 3,
      method: "tools/call",
      params: %{
        name: "reset_scene",
        arguments: %{}
      }
    })

    # Read responses
    receive_responses(port)

    Port.close(port)
  end

  defp send_request(port, request) do
    json = Jason.encode!(request)
    IO.puts(:stderr, "📤 Sending: #{json}")
    Port.command(port, json <> "\n")
    Process.sleep(100)
  end

  defp receive_responses(port) do
    receive do
      {^port, {:data, data}} ->
        IO.puts(:stderr, "📥 Received: #{data}")
        receive_responses(port)

      {^port, {:exit_status, status}} ->
        IO.puts(:stderr, "Server exited with status: #{status}")
    after
      3000 ->
        IO.puts(:stderr, "Timeout waiting for responses")
    end
  end
end

TestStdio.run()

