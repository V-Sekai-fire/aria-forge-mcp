# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.NativeService do
  @moduledoc """
  Native BEAM service for Blender bpy MCP using ex_mcp library.
  Provides 3D modeling and rendering tools via MCP protocol.
  """

  # Suppress warnings from ex_mcp DSL generated code
  @compile {:no_warn_undefined, :no_warn_pattern}

  use ExMCP.Server,
    name: "Blender bpy MCP Server",
    version: "0.1.0"

  # Whitelist of allowed commands
  @allowed_commands MapSet.new([
    "create_cube",
    "create_sphere",
    "get_scene_info",
    "take_photo"
  ])

  # Command registry - maps command names to handler functions and schemas
  @commands %{
    "create_cube" => %{
      handler: :handle_create_cube,
      schema: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Name for the cube object", default: "Cube"},
          location: %{type: "array", items: %{type: "number"}, description: "Location as [x, y, z] coordinates", default: [0, 0, 0]},
          size: %{type: "number", description: "Size of the cube", default: 2.0}
        }
      },
      description: "Create a cube object in the Blender scene"
    },
    "create_sphere" => %{
      handler: :handle_create_sphere,
      schema: %{
        type: "object",
        properties: %{
          name: %{type: "string", description: "Name for the sphere object", default: "Sphere"},
          location: %{type: "array", items: %{type: "number"}, description: "Location as [x, y, z] coordinates", default: [0, 0, 0]},
          radius: %{type: "number", description: "Radius of the sphere", default: 1.0}
        }
      },
      description: "Create a sphere object in the Blender scene"
    },
    "get_scene_info" => %{
      handler: :handle_get_scene_info,
      schema: %{type: "object", properties: %{}},
      description: "Get information about the current Blender scene"
    },
    "take_photo" => %{
      handler: :handle_take_photo,
      schema: %{
        type: "object",
        properties: %{
          filepath: %{type: "string", description: "Output file path for the photo", default: "photo.png"},
          camera_location: %{type: "array", items: %{type: "number"}, description: "Camera position as [x, y, z] coordinates", default: [7.0, -7.0, 5.0]},
          camera_rotation: %{type: "array", items: %{type: "number"}, description: "Camera rotation as [x, y, z] Euler angles in degrees", default: [60.0, 0.0, 45.0]},
          focal_length: %{type: "number", description: "Camera focal length in mm", default: 50.0},
          resolution_x: %{type: "integer", description: "Render width", default: 1920},
          resolution_y: %{type: "integer", description: "Render height", default: 1080}
        }
      },
      description: "Take a photo (render the current scene from camera view)"
    }
  }



  # Command-based tools

  deftool "bpy_list_commands" do
    meta do
      name("List Commands")
      description("List all available bpy commands with their schemas")
    end

    input_schema(%{
      type: "object",
      properties: %{}
    })
  end

  deftool "bpy_execute_command" do
    meta do
      name("Execute Command")
      description("Execute a list of bpy commands with their arguments")
    end

    input_schema(%{
      type: "object",
      properties: %{
        commands: %{
          type: "array",
          description: "List of commands to execute",
          items: %{
            type: "object",
            properties: %{
              command: %{type: "string", description: "Name of the command to execute"},
              args: %{type: "object", description: "Arguments for the command", default: %{}}
            },
            required: ["command"]
          }
        }
      },
      required: ["commands"]
    })
  end

  # Command-based tool handlers

  @impl true
  def handle_tool_call("bpy_list_commands", _args, state) do
    commands = Enum.map(@commands, fn {name, %{schema: schema, description: description}} ->
      %{name: name, schema: schema, description: description}
    end)

    {:ok, %{content: [text("Available commands: #{inspect(commands)}")]}, state}
  end

  @impl true
  def handle_tool_call("bpy_execute_command", %{"commands" => commands} = _args, state) do
    # Reset scene for fresh command list execution
    case BpyMcp.BpyTools.reset_scene() do
      {:ok, _reset_msg} ->
        # Execute commands individually but return only the last result
        execute_commands_individually(commands, state)

      {:error, reset_reason} ->
        {:error, "Failed to reset scene: #{reset_reason}", state}
    end
  end

  # Execute commands individually but return only the last result
  defp execute_commands_individually(commands, state) do
    results = Enum.map(commands, fn %{"command" => command_name} = command_spec ->
      command_args = Map.get(command_spec, "args", %{})

      # Check whitelist first
      if MapSet.member?(@allowed_commands, command_name) do
        case Map.get(@commands, command_name) do
          %{handler: handler} ->
            case apply(__MODULE__, handler, [command_args, state]) do
              {:ok, response, _new_state} -> {:ok, command_name, response}
              {:error, reason, _new_state} -> {:error, command_name, reason}
            end
          nil ->
            {:error, command_name, "Command not implemented: #{command_name}"}
        end
      else
        {:error, command_name, "Command not allowed: #{command_name}"}
      end
    end)

    # Return only the last command's result
    case List.last(results) do
      {:ok, last_cmd, response} ->
        {:ok, response, state}
      {:error, last_cmd, reason} ->
        {:error, "Command '#{last_cmd}' failed: #{reason}", state}
      nil ->
        {:error, "No commands executed", state}
    end
  end

  # Command handler functions - return MCP response format

  def handle_create_cube(args, state) do
    name = Map.get(args, "name", "Cube")
    location = Map.get(args, "location", [0, 0, 0])
    size = Map.get(args, "size", 2.0)
    case BpyMcp.BpyTools.create_cube(name, location, size) do
      {:ok, result} ->
        {:ok, %{content: [text("Result: #{result}")]}, state}
      {:error, reason} ->
        {:error, "Failed to create cube: #{reason}", state}
    end
  end

  def handle_create_sphere(args, state) do
    name = Map.get(args, "name", "Sphere")
    location = Map.get(args, "location", [0, 0, 0])
    radius = Map.get(args, "radius", 1.0)
    case BpyMcp.BpyTools.create_sphere(name, location, radius) do
      {:ok, result} ->
        {:ok, %{content: [text("Result: #{result}")]}, state}
      {:error, reason} ->
        {:error, "Failed to create sphere: #{reason}", state}
    end
  end

  def handle_get_scene_info(_args, state) do
    case BpyMcp.BpyTools.get_scene_info() do
      {:ok, info} ->
        {:ok, %{content: [text("Scene info: #{inspect(info)}")]}, state}
      {:error, reason} ->
        {:error, "Failed to get scene info: #{reason}", state}
    end
  end

  def handle_take_photo(args, state) do
    filepath = Map.get(args, "filepath", "photo.png")
    camera_location = Map.get(args, "camera_location", [7.0, -7.0, 5.0])
    camera_rotation = Map.get(args, "camera_rotation", [60.0, 0.0, 45.0])
    focal_length = Map.get(args, "focal_length", 50.0)
    resolution_x = Map.get(args, "resolution_x", 1920)
    resolution_y = Map.get(args, "resolution_y", 1080)
    case BpyMcp.BpyTools.take_photo(filepath, camera_location, camera_rotation, focal_length, resolution_x, resolution_y) do
      {:ok, result} ->
        {:ok, %{content: [text("Result: #{result}")]}, state}
      {:error, reason} ->
        {:error, "Failed to take photo: #{reason}", state}
    end
  end

  # Fallback for unknown tools
  @impl true
  def handle_tool_call(tool_name, _args, state) do
    {:error, "Tool not found: #{tool_name}", state}
  end

  # Helper function to parse PID from string
  defp parse_pid(pid_str) when is_binary(pid_str) do
    try do
      # For now, we'll use a simple approach - in production,
      # you'd want more robust PID serialization/deserialization
      case pid_str do
        "<0." <> _rest -> {:ok, :erlang.list_to_pid(String.to_charlist(pid_str))}
        _ -> {:error, :invalid_pid}
      end
    rescue
      _ -> {:error, :invalid_pid}
    end
  end

  defp parse_pid(_), do: {:error, :invalid_pid}
end
