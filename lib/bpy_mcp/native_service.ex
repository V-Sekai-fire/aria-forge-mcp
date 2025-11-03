# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.NativeService do
  @moduledoc """
  Native BEAM service for Blender bpy MCP using ex_mcp library.
  Provides 3D modeling and rendering tools via MCP protocol.
  """

  alias BpyMcp.NativeService.Context
  alias BpyMcp.NativeService.SchemaConverter

  # Suppress warnings from ex_mcp DSL generated code
  @compile {:no_warn_undefined, :no_warn_pattern}

  use ExMCP.Server,
    name: "Blender bpy MCP Server",
    version: "0.1.0"

  # Individual command tools - each command is now a separate MCP tool

  deftool "reset_scene" do
    meta do
      name("Reset Scene")
      description("Resets the Blender scene to a clean state")
    end

    input_schema(%{
      type: "object",
      properties: %{
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      }
    })
  end

  deftool "create_cube" do
    meta do
      name("Create Cube")
      description("Create a cube object in the Blender scene")
    end

    input_schema(%{
      type: "object",
      properties: %{
        name: %{type: "string", description: "Name for the cube object", default: "Cube"},
        location: %{
          type: "array",
          items: %{type: "number"},
          description: "Location as [x, y, z] coordinates",
          default: [0, 0, 0]
        },
        size: %{type: "number", description: "Size of the cube", default: 2.0},
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      }
    })
  end

  deftool "create_sphere" do
    meta do
      name("Create Sphere")
      description("Create a sphere object in the Blender scene")
    end

    input_schema(%{
      type: "object",
      properties: %{
        name: %{type: "string", description: "Name for the sphere object", default: "Sphere"},
        location: %{
          type: "array",
          items: %{type: "number"},
          description: "Location as [x, y, z] coordinates",
          default: [0, 0, 0]
        },
        radius: %{type: "number", description: "Radius of the sphere", default: 1.0},
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      }
    })
  end

  deftool "get_scene_info" do
    meta do
      name("Get Scene Info")
      description("Get information about the current Blender scene")
    end

    input_schema(%{
      type: "object",
      properties: %{
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      }
    })
  end

  deftool "export_bmesh" do
    meta do
      name("Export BMesh")
      description("Export the current Blender scene as BMesh data in EXT_mesh_bmesh format")
    end

    input_schema(%{
      type: "object",
      properties: %{
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      }
    })
  end

  deftool "import_bmesh" do
    meta do
      name("Import BMesh")
      description("Import BMesh data from glTF JSON with EXT_mesh_bmesh extension")
    end

    input_schema(%{
      type: "object",
      properties: %{
        gltf_data: %{type: "string", description: "glTF JSON data with EXT_mesh_bmesh extension to import"},
        context_token: %{
          type: "string",
          description: "Optional context token (macaroon) for scene context. If not provided, uses default context."
        },
        scene_id: %{
          type: "string",
          description: "Optional scene ID. If not provided, uses default scene."
        }
      },
      required: ["gltf_data"]
    })
  end

  # Override handle_request to intercept tools/list and convert input_schema to inputSchema
  # This ensures tools returned have camelCase keys as required by MCP specification
  @impl true
  def handle_request(%{"method" => "tools/list"} = request, _params, state) do
    # Get tools directly using get_tools() from ex_mcp
    tools_map = get_tools()
    
    # Convert tools map to list format required by MCP spec
    tools_list = 
      tools_map
      |> Map.values()
      |> Enum.map(fn tool ->
        # Convert tool to MCP format with camelCase keys
        %{
          "name" => tool.name,
          "description" => tool.description,
          "inputSchema" => SchemaConverter.convert_keys_to_camel_case(tool.input_schema)
        }
      end)
    
    # Get id from request if present
    id = Map.get(request, "id", nil)
    
    # Build proper JSON-RPC response
    response = 
      %{
        "jsonrpc" => "2.0",
        "result" => %{
          "tools" => tools_list
        }
      }
      |> then(fn r -> if id, do: Map.put(r, "id", id), else: r end)
    
    {:reply, response, state}
  end

  alias BpyMcp.NativeService.Context

  # Individual tool handlers - each command is now handled directly

  @impl true
  def handle_tool_call("reset_scene", args, state) do
    with {:ok, temp_dir, context_pid} <- Context.get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.reset_scene(temp_dir) do
      # Encode context token with updated metadata
      case Context.encode_context_token(context_pid, %{scene_id: Context.get_scene_id(context_pid), operation_count: 0}) do
        {:ok, _token} ->
          {:ok, %{content: [text("Scene reset successfully")]}, state}
        _ ->
          {:ok, %{content: [text("Result: #{result}")]}, state}
      end
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("create_cube", args, state) do
    name = Map.get(args, "name", "Cube")
    location = Map.get(args, "location", [0, 0, 0])
    size = Map.get(args, "size", 2.0)

    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.create_cube(name, location, size, temp_dir) do
      {:ok, %{content: [text("Result: #{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("create_sphere", args, state) do
    name = Map.get(args, "name", "Sphere")
    location = Map.get(args, "location", [0, 0, 0])
    radius = Map.get(args, "radius", 1.0)

    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyTools.create_sphere(name, location, radius, temp_dir) do
      {:ok, %{content: [text("Result: #{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("get_scene_info", args, state) do
    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, info} <- BpyMcp.BpyTools.get_scene_info(temp_dir) do
      {:ok, %{content: [text("Scene info: #{inspect(info)}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("export_bmesh", args, state) do
    with {:ok, temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, bmesh_data} <- BpyMcp.BpyMesh.export_bmesh_scene(temp_dir) do
      {:ok, %{content: [%{"type" => "text", "text" => Jason.encode!(bmesh_data)}]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def handle_tool_call("import_bmesh", args, state) do
    gltf_data = Map.get(args, "gltf_data", "")

    with {:ok, _temp_dir, _context_pid} <- Context.get_or_create_context(args, state),
         {:ok, result} <- BpyMcp.BpyMesh.import_bmesh_scene(gltf_data) do
      {:ok, %{content: [text("Result: #{result}")]}, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  # Fallback for unknown tools
  @impl true
  def handle_tool_call(tool_name, _args, state) do
    {:error, "Tool not found: #{tool_name}", state}
  end
end
