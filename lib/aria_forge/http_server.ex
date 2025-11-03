# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.HTTPServer do
  @moduledoc """
  HTTP server for the bpy MCP server using Plug.

  This module provides an HTTP interface for the MCP protocol,
  allowing clients to connect via HTTP instead of stdio.
  """

  use Plug.Router

  require Logger

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason, pass: ["*/*"]
  plug :dispatch

  # Root SSE endpoint (for clients that expect SSE at root)
  get "/" do
    handle_sse_request(conn)
  end

  # Root MCP protocol endpoint (for SSE clients)
  post "/" do
    handle_mcp_request(conn)
  end

  # MCP protocol endpoint
  post "/mcp" do
    handle_mcp_request(conn)
  end

  # SSE endpoint for streaming (MCP standard)
  get "/sse" do
    handle_sse_request(conn)
  end

  # Alternative SSE endpoint that some clients might expect
  get "/events" do
    handle_sse_request(conn)
  end

  # Health check endpoint
  get "/health" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", server: "aria-forget"}))
  end

  # Catch-all route
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "Not found"}))
  end

  # Handle MCP requests
  defp handle_mcp_request(conn) do
    # Try to get JSON from body_params first, then try parsing raw body
    json_data = case conn.body_params do
      %Plug.Conn.Unfetched{} ->
        parse_raw_body(conn)
      %{} = params when map_size(params) > 0 ->
        params
      _ ->
        parse_raw_body(conn)
    end

    case json_data do
      %{"jsonrpc" => "2.0", "method" => method, "params" => params, "id" => id} ->
        handle_mcp_method(conn, method, params, id)

      %{"jsonrpc" => "2.0", "method" => method, "id" => id} ->
        handle_mcp_method(conn, method, %{}, id)

      _ ->
        send_mcp_error(conn, -32600, "Invalid Request")
    end
  rescue
    error ->
      Logger.error("MCP request error: #{inspect(error)}")
      send_mcp_error(conn, -32603, "Internal error")
  end

  # Parse raw request body as JSON
  defp parse_raw_body(conn) do
    case conn do
      %{body_params: %Plug.Conn.Unfetched{}} ->
        # Body not parsed yet, try to read it
        {:ok, body, _conn} = read_body(conn)
        case Jason.decode(body) do
          {:ok, data} -> data
          _ -> %{}
        end

      _ ->
        %{}
    end
  end

  # Handle MCP method calls
  defp handle_mcp_method(conn, method, params, id) do
    case method do
      "initialize" ->
        response = %{
          jsonrpc: "2.0",
          id: id,
          result: %{
            protocolVersion: "2025-03-26",
            serverInfo: %{name: "aria-forget", version: "0.1.0"},
            capabilities: %{
              tools: %{listChanged: true}
            }
          }
        }
        send_json_response(conn, 200, response)

      "tools/list" ->
        # Return the available tools
        tools = [
          %{
            name: "list_commands",
            description: "List all available bpy commands with their schemas",
            inputSchema: %{
              "type" => "object",
              "properties" => %{}
            }
          },
          %{
            name: "execute_command",
            description: "Execute a list of bpy commands with their arguments",
            inputSchema: %{
              "type" => "object",
              "properties" => %{
                "commands" => %{
                  "type" => "array",
                  "description" => "List of commands to execute",
                  "items" => %{
                    "type" => "object",
                    "properties" => %{
                      "command" => %{"type" => "string", "description" => "Name of the command to execute"},
                      "args" => %{"type" => "object", "description" => "Arguments for the command", "default" => %{}}
                    },
                    "required" => ["command"]
                  }
                }
              },
              "required" => ["commands"]
            }
          }
        ]

        response = %{
          jsonrpc: "2.0",
          id: id,
          result: %{tools: tools}
        }
        send_json_response(conn, 200, response)

      "tools/call" ->
        handle_tool_call(conn, params, id)

      _ ->
        send_mcp_error(conn, -32601, "Method not found")
    end
  end

  # Handle tool calls
  defp handle_tool_call(conn, %{"name" => tool_name, "arguments" => args}, id) do
    case tool_name do
      "list_commands" ->
        case AriaForge.NativeService.handle_tool_call("list_commands", %{}, %{}) do
          {:ok, %{content: content}, _state} ->
            response = %{
              jsonrpc: "2.0",
              id: id,
              result: %{content: content}
            }
            send_json_response(conn, 200, response)

          _ ->
            send_mcp_error(conn, -32603, "Tool execution failed")
        end

      "execute_command" ->
        case AriaForge.NativeService.handle_tool_call("execute_command", args, %{}) do
          {:ok, %{content: content}, _state} ->
            response = %{
              jsonrpc: "2.0",
              id: id,
              result: %{content: content}
            }
            send_json_response(conn, 200, response)

          {:error, reason, _state} ->
            send_mcp_error(conn, -32603, "Tool execution failed: #{reason}")
        end

      _ ->
        send_mcp_error(conn, -32601, "Tool not found")
    end
  end

  # Parse tools from the content returned by bpy_list_commands
  # Unused - keeping for potential future use
  # defp parse_tools_from_content(content) do
  #   # The content is a list with one text element containing the tools in Elixir map syntax
  #   case content do
  #     [%{"type" => "text", "text" => text}] ->
  #       # Extract the commands from the text
  #       # The text format is: "Available commands: [map1, map2, ...]"
  #       case extract_commands_from_text(text) do
  #         commands when is_list(commands) ->
  #           Enum.map(commands, fn command ->
  #             %{
  #               name: command["name"],
  #               description: command["description"],
  #               inputSchema: command["schema"]
  #             }
  #           end)
  #
  #         _ ->
  #           []
  #       end
  #
  #     _ ->
  #       []
  #   end
  # end

  # Extract commands from the text format
  # Unused - keeping for potential future use
  # defp extract_commands_from_text(text) do
  #   # Simple parsing of the Elixir map syntax
  #   # This is a basic implementation - in production you'd want proper Elixir AST parsing
  #   try do
  #     # Remove the "Available commands: " prefix
  #     commands_str = String.replace(text, "Available commands: ", "")
  #
  #     # Parse the Elixir map syntax (simplified)
  #     # This is a very basic parser that works for our specific format
  #     parse_elixir_maps(commands_str)
  #   rescue
  #     _ -> []
  #   end
  # end

  # Very basic parser for our specific Elixir map format
  # Unused - keeping for potential future use
  # defp parse_elixir_maps(str) do
  #   # This is a simplified parser that extracts the key information
  #   # In production, you'd want to use Code.eval_string or proper AST parsing
  #
  #   # Extract command entries
  #   commands = []
  #
  #   # Find all %{...} blocks
  #   Regex.scan(~r/%\{[^}]+\}/, str)
  #   |> Enum.each(fn [map_str] ->
  #     # Extract name
  #     name_match = Regex.run(~r/name:\s*"([^"]+)"/, map_str)
  #     name = if name_match, do: Enum.at(name_match, 1), else: nil
  #
  #     # Extract description
  #     desc_match = Regex.run(~r/description:\s*"([^"]+)"/, map_str)
  #     description = if desc_match, do: Enum.at(desc_match, 1), else: nil
  #
  #     # For schema, we'll create a simplified version
  #     # In a real implementation, you'd parse the full schema
  #     schema = %{
  #       "type" => "object",
  #       "properties" => %{}
  #     }
  #
  #     if name && description do
  #       commands = [%{"name" => name, "description" => description, "schema" => schema} | commands]
  #     end
  #   end)
  #
  #   Enum.reverse(commands)
  # end

  # Send MCP error response
  defp send_mcp_error(conn, code, message) do
    error_response = %{
      jsonrpc: "2.0",
      error: %{
        code: code,
        message: message
      }
    }
    send_json_response(conn, 200, error_response)
  end

  # Handle SSE request
  defp handle_sse_request(conn) do
    # Set up Server-Sent Events headers
    conn =
      conn
      |> put_resp_header("content-type", "text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> put_resp_header("access-control-allow-origin", "*")
      |> put_resp_header("access-control-allow-headers", "content-type")
      |> send_chunked(200)

    # Send initial message event (some MCP clients expect this)
    message_event = "event: message\ndata: #{Jason.encode!(%{type: "connection_ack"})}\n\n"

    case chunk(conn, message_event) do
      {:ok, conn} ->
        # Send endpoint event (MCP SSE protocol) - use /mcp for MCP posts
        endpoint_url = "#{conn.scheme}://#{conn.host}:#{conn.port}/mcp"
        endpoint_event = "event: endpoint\ndata: #{Jason.encode!(%{uri: endpoint_url})}\n\n"

        case chunk(conn, endpoint_event) do
          {:ok, conn} ->
            # Keep the connection alive with periodic pings
            # In a full implementation, this would also send notifications
            spawn_link(fn -> keep_alive_loop(conn) end)
            conn

          {:error, _reason} ->
            conn
        end

      {:error, _reason} ->
        conn
    end
  end

  # Keep the SSE connection alive with periodic messages
  defp keep_alive_loop(conn) do
    Process.sleep(30000)  # 30 seconds
    case chunk(conn, "event: ping\ndata: {}\n\n") do
      {:ok, _conn} ->
        keep_alive_loop(conn)  # Continue the loop

      {:error, _reason} ->
        :ok  # Connection closed, stop the loop
    end
  end

  # Send JSON response
  defp send_json_response(conn, status, data) do
    case Jason.encode(data) do
      {:ok, json} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(status, json)

      {:error, _reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{error: "JSON encoding failed"}))
    end
  end
end
