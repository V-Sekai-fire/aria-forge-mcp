# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Mcp.Server do
  @moduledoc """
  Mix task to run the MCP bpy HTTP server.

  This task starts the MCP server that provides 3D modeling
  capabilities via the Model Context Protocol over HTTP.

  ## Usage

      mix mcp.server

  The server will run on port 4000 (or PORT environment variable),
  providing MCP capabilities via HTTP endpoints.

  ## Endpoints

  - POST /mcp - MCP protocol endpoint
  - GET /health - Health check endpoint
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    # Parse command line arguments
    {opts, _} = OptionParser.parse!(args, strict: [port: :integer, transport: :string])

    # Determine transport type
    transport = 
      case Keyword.get(opts, :transport) || System.get_env("MCP_TRANSPORT", "http") do
        "stdio" -> :stdio
        "sse" -> :sse
        _ -> :http
      end

    # Set port from command line or environment (only for HTTP/SSE)
    port = opts[:port] || System.get_env("PORT", "4000") |> String.to_integer()
    System.put_env("PORT", to_string(port))
    System.put_env("MCP_TRANSPORT", to_string(transport))

    Mix.Task.run("app.start")

    # Start the MCP application
    Application.ensure_all_started(:aria_forge)

    case transport do
      :stdio ->
        IO.puts(:stderr, "🚀 aria-forge stdio server started")
        IO.puts(:stderr, "📡 Ready to accept MCP protocol messages via stdin/stdout")

      _ ->
        IO.puts("🚀 aria-forge #{transport} server started on port #{port}")
        IO.puts("📡 MCP endpoint: http://localhost:#{port}")
        if transport == :sse do
          IO.puts("📡 SSE endpoint: http://localhost:#{port}/sse")
        end
        IO.puts("💚 Health check: http://localhost:#{port}/health")
    end

    # Keep the process running
    Process.sleep(:infinity)
  end
end