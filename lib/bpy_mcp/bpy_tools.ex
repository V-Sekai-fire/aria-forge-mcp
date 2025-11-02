# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyTools do
  @moduledoc """
  Blender bpy tools exposed via MCP using Pythonx for 3D operations.

  This module provides MCP tools that wrap Blender's bpy functionality for:
  - Creating objects (cubes, spheres, etc.)
  - Manipulating materials
  - Rendering scenes
  - Scene management
  """

  require Logger

  @type bpy_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Creates a cube object in the Blender scene.

  ## Parameters
    - name: Name for the cube object
    - location: [x, y, z] coordinates for the cube
    - size: Size of the cube

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec create_cube(String.t(), [number()], number()) :: bpy_result()
  def create_cube(name \\ "Cube", location \\ [0, 0, 0], size \\ 2.0) do
    case ensure_pythonx() do
      :ok ->
        do_create_cube(name, location, size)

      :mock ->
        mock_create_cube(name, location, size)
    end
  end

  defp mock_create_cube(name, location, size) do
    {:ok, "Mock created cube '#{name}' at #{inspect(location)} with size #{size}"}
  end

  defp do_create_cube(name, location, size) do
    # Ensure scene FPS is set to 30
    ensure_scene_fps()

    code = """
    import bpy

    # Create cube
    bpy.ops.mesh.primitive_cube_add(size=#{size}, location=#{inspect(location)})
    cube = bpy.context.active_object
    cube.name = '#{name}'

    result = f"Created cube '{cube.name}' at {list(cube.location)} with size #{size}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode create_cube result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  @doc """
  Creates a sphere object in the Blender scene.

  ## Parameters
    - name: Name for the sphere object
    - location: [x, y, z] coordinates for the sphere
    - radius: Radius of the sphere

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec create_sphere(String.t(), [number()], number()) :: bpy_result()
  def create_sphere(name \\ "Sphere", location \\ [0, 0, 0], radius \\ 1.0) do
    case ensure_pythonx() do
      :ok ->
        do_create_sphere(name, location, radius)

      :mock ->
        mock_create_sphere(name, location, radius)
    end
  end

  defp mock_create_sphere(name, location, radius) do
    {:ok, "Mock created sphere '#{name}' at #{inspect(location)} with radius #{radius}"}
  end

  defp do_create_sphere(name, location, radius) do
    # Ensure scene FPS is set to 30
    ensure_scene_fps()

    code = """
    import bpy

    # Create sphere
    bpy.ops.mesh.primitive_uv_sphere_add(radius=#{radius}, location=#{inspect(location)})
    sphere = bpy.context.active_object
    sphere.name = '#{name}'

    result = f"Created sphere '{sphere.name}' at {list(sphere.location)} with radius #{radius}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode create_sphere result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  @doc """
  Sets a material on an object.

  ## Parameters
    - object_name: Name of the object to apply material to
    - material_name: Name of the material
    - color: [r, g, b, a] color values

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec set_material(String.t(), String.t(), [number()]) :: bpy_result()
  def set_material(object_name, material_name \\ "Material", color \\ [0.8, 0.8, 0.8, 1.0]) do
    case ensure_pythonx() do
      :ok ->
        do_set_material(object_name, material_name, color)

      :mock ->
        mock_set_material(object_name, material_name, color)
    end
  end

  defp mock_set_material(object_name, material_name, color) do
    {:ok, "Mock set material '#{material_name}' with color #{inspect(color)} on object '#{object_name}'"}
  end

  defp do_set_material(object_name, material_name, color) do
    code = """
    import bpy

    # Find object
    obj = bpy.data.objects.get('#{object_name}')
    if not obj:
        result = f"Object '{obj_name}' not found"
    else:
        # Create or get material
        mat = bpy.data.materials.get('#{material_name}')
        if not mat:
            mat = bpy.data.materials.new('#{material_name}')
            mat.use_nodes = True
            bsdf = mat.node_tree.nodes["Principled BSDF"]
            bsdf.inputs["Base Color"].default_value = #{inspect(color)}

        # Assign material
        if obj.data.materials:
            obj.data.materials[0] = mat
        else:
            obj.data.materials.append(mat)

        result = f"Set material '{mat.name}' on object '{obj.name}'"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode set_material result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  @doc """
  Renders the current scene to an image file.

  ## Parameters
    - filepath: Output file path
    - resolution_x: Render width
    - resolution_y: Render height

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec render_image(String.t(), integer(), integer()) :: bpy_result()
  def render_image(filepath, resolution_x \\ 1920, resolution_y \\ 1080) do
    case ensure_pythonx() do
      :ok ->
        do_render_image(filepath, resolution_x, resolution_y)

      :mock ->
        mock_render_image(filepath, resolution_x, resolution_y)
    end
  end

  defp mock_render_image(filepath, resolution_x, resolution_y) do
    {:ok, "Mock rendered image to #{filepath} at #{resolution_x}x#{resolution_y}"}
  end

  defp do_render_image(filepath, resolution_x, resolution_y) do
    # Ensure scene FPS is set to 30
    ensure_scene_fps()

    code = """
    import bpy

    # Set render settings
    bpy.context.scene.render.resolution_x = #{resolution_x}
    bpy.context.scene.render.resolution_y = #{resolution_y}
    bpy.context.scene.render.filepath = '#{filepath}'

    # Render
    bpy.ops.render.render(write_still=True)

    result = f"Rendered image to #{filepath} at #{resolution_x}x#{resolution_y}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode render_image result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  @doc """
  Gets information about the current Blender scene.

  ## Returns
    - `{:ok, map()}` - Scene information
    - `{:error, String.t()}` - Error message
  """
  @spec get_scene_info() :: bpy_result()
  def get_scene_info do
    case ensure_pythonx() do
      :ok ->
        do_get_scene_info()

      :mock ->
        mock_get_scene_info()
    end
  end

  defp mock_get_scene_info do
    {:ok, %{
      "scene_name" => "Mock Scene",
      "frame_current" => 1,
      "frame_start" => 1,
      "frame_end" => 250,
      "fps" => 30,
      "fps_base" => 1,
      "objects" => ["Cube", "Light", "Camera"],
      "active_object" => "Cube"
    }}
  end

  defp do_get_scene_info do
    # Ensure scene FPS is set to 30 before getting info
    ensure_scene_fps()

    code = """
    import bpy

    scene = bpy.context.scene
    objects = [obj.name for obj in scene.objects]
    active_object = bpy.context.active_object.name if bpy.context.active_object else None

    result = {
        "scene_name": scene.name,
        "frame_current": scene.frame_current,
        "frame_start": scene.frame_start,
        "frame_end": scene.frame_end,
        "fps": scene.render.fps,
        "fps_base": scene.render.fps_base,
        "objects": objects,
        "active_object": active_object
    }
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_map(result) -> {:ok, result}
          _ -> {:error, "Failed to decode scene info"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  # Helper functions
  @doc """
  Ensures the Blender scene is set to 30 FPS for animations.
  Only executes when Pythonx/Blender is available.
  """
  @spec ensure_scene_fps() :: :ok
  defp ensure_scene_fps do
    # Only try to set FPS if Pythonx is actually available
    case check_pythonx_availability() do
      :ok ->
        code = """
        import bpy

        # Set scene FPS to 30
        bpy.context.scene.render.fps = 30
        bpy.context.scene.render.fps_base = 1
        """

        case Pythonx.eval(code, %{}) do
          {_result, _globals} -> :ok
          _ -> :ok  # Continue even if setting FPS fails
        end
      :mock ->
        :ok  # In mock mode, just return ok
    end
  rescue
    _ -> :ok  # Continue even if Pythonx fails
  end

  defp ensure_pythonx do
    # Force mock mode during testing to avoid Blender initialization
    if Application.get_env(:bpy_mcp, :force_mock, false) or System.get_env("MIX_ENV") == "test" do
      :mock
    else
      case Application.ensure_all_started(:pythonx) do
        {:error, _reason} ->
          :mock

        {:ok, _} ->
          check_pythonx_availability()
      end
    end
  rescue
    _ -> :mock
  end

  defp check_pythonx_availability do
    case Pythonx.eval("1 + 1", %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          2 -> :ok
          _ -> :mock
        end

      _ ->
        :mock
    end
  end

  # Test helper functions
  @doc false
  def test_mock_create_cube(name, location, size), do: mock_create_cube(name, location, size)
  @doc false
  def test_mock_create_sphere(name, location, radius), do: mock_create_sphere(name, location, radius)
  @doc false
  def test_mock_set_material(object_name, material_name, color), do: mock_set_material(object_name, material_name, color)
  @doc false
  def test_mock_render_image(filepath, resolution_x, resolution_y), do: mock_render_image(filepath, resolution_x, resolution_y)
  @doc false
  def test_mock_get_scene_info(), do: mock_get_scene_info()
end
