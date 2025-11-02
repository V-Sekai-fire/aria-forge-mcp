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

    # Format location as Python tuple
    location_str = location |> Enum.map(&to_string/1) |> Enum.join(", ")

    code = """
    import bpy

    # Ensure we have a scene
    if not bpy.context.scene:
        bpy.ops.scene.new(type='NEW')

    # Create cube
    bpy.ops.mesh.primitive_cube_add(size=#{size}, location=(#{location_str}))

    # Safely get the active object
    try:
        cube = bpy.context.active_object
        if cube:
            cube.name = '#{name}'
            result = f"Created cube '{cube.name}' at {list(cube.location)} with size #{size}"
        else:
            result = f"Failed to create cube - no active object after creation"
    except AttributeError:
        result = f"Failed to create cube - context error accessing active object"
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

    # Format location as Python tuple
    location_str = location |> Enum.map(&to_string/1) |> Enum.join(", ")

    code = """
    import bpy

    # Ensure we have a scene
    if not bpy.context.scene:
        bpy.ops.scene.new(type='NEW')

    # Create sphere
    bpy.ops.mesh.primitive_uv_sphere_add(radius=#{radius}, location=(#{location_str}))

    # Safely get the active object
    try:
        sphere = bpy.context.active_object
        if sphere:
            sphere.name = '#{name}'
            result = f"Created sphere '{sphere.name}' at {list(sphere.location)} with radius #{radius}"
        else:
            result = f"Failed to create sphere - no active object after creation"
    except AttributeError:
        result = f"Failed to create sphere - context error accessing active object"
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
        result = f"Object '#{object_name}' not found"
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
  Takes a photo (renders the current scene from camera view).

  ## Parameters
    - filepath: Output file path for the photo
    - camera_location: [x, y, z] position of the camera
    - camera_rotation: [x, y, z] rotation of the camera (Euler angles in degrees)
    - focal_length: Camera focal length in mm
    - resolution_x: Render width
    - resolution_y: Render height

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec take_photo(String.t(), [number()], [number()], number(), integer(), integer()) :: bpy_result()
  def take_photo(filepath \\ "photo.png", camera_location \\ [7.0, -7.0, 5.0], camera_rotation \\ [60.0, 0.0, 45.0], focal_length \\ 50.0, resolution_x \\ 1920, resolution_y \\ 1080) do
    case ensure_pythonx() do
      :ok ->
        do_take_photo(filepath, camera_location, camera_rotation, focal_length, resolution_x, resolution_y)

      :mock ->
        mock_take_photo(filepath, camera_location, camera_rotation, focal_length, resolution_x, resolution_y)
    end
  end

  defp mock_take_photo(filepath, camera_location, camera_rotation, focal_length, resolution_x, resolution_y) do
    {:ok, "Mock took photo and saved to #{filepath} at #{resolution_x}x#{resolution_y} from camera at #{inspect(camera_location)} with rotation #{inspect(camera_rotation)} and focal length #{focal_length}mm"}
  end

  defp do_take_photo(filepath, camera_location, camera_rotation, focal_length, resolution_x, resolution_y) do
    # Ensure scene FPS is set to 30
    ensure_scene_fps()

    # Format location and rotation as Python tuples
    location_str = camera_location |> Enum.map(&to_string/1) |> Enum.join(", ")
    rotation_str = camera_rotation |> Enum.map(&to_string/1) |> Enum.join(", ")

    code = """
    import bpy
    import math

    # Set render settings for photo
    bpy.context.scene.render.resolution_x = #{resolution_x}
    bpy.context.scene.render.resolution_y = #{resolution_y}
    bpy.context.scene.render.filepath = '#{filepath}'

    # Ensure camera exists
    if not bpy.context.scene.camera:
        bpy.ops.object.camera_add()
        camera = bpy.context.active_object
        camera.name = 'Camera'
        bpy.context.scene.camera = camera

    # Get the camera
    camera = bpy.context.scene.camera

    # Set camera position
    camera.location = (#{location_str})

    # Set camera rotation (convert degrees to radians)
    camera.rotation_euler = (math.radians(#{Enum.at(camera_rotation, 0)}), math.radians(#{Enum.at(camera_rotation, 1)}), math.radians(#{Enum.at(camera_rotation, 2)}))

    # Set camera focal length
    camera.data.lens = #{focal_length}

    # Render the photo
    bpy.ops.render.render(write_still=True)

    result = f"Took photo and saved to #{filepath} at #{resolution_x}x#{resolution_y} from camera at (#{location_str}) with rotation (#{rotation_str}) and focal length #{focal_length}mm"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode take_photo result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  @doc """
  Resets the Blender scene to a clean state by removing all objects.

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec reset_scene() :: bpy_result()
  def reset_scene do
    case ensure_pythonx() do
      :ok ->
        do_reset_scene()

      :mock ->
        mock_reset_scene()
    end
  end

  defp mock_reset_scene do
    {:ok, "Mock reset scene - cleared all objects"}
  end

  defp do_reset_scene do
    code = """
import bpy

# Ensure we have a scene
if not bpy.context.scene:
    bpy.ops.scene.new(type='NEW')

scene = bpy.context.scene

# Remove all objects from the scene
for obj in list(scene.objects):
    bpy.data.objects.remove(obj, do_unlink=True)

# Clear any orphaned data
for mesh in list(bpy.data.meshes):
    if mesh.users == 0:
        bpy.data.meshes.remove(mesh)

for material in list(bpy.data.materials):
    if material.users == 0:
        bpy.data.materials.remove(material)

# Set basic scene properties
scene.render.fps = 30
scene.render.fps_base = 1
scene.frame_current = 1
scene.frame_start = 1
scene.frame_end = 250

result = "Scene reset - all objects cleared"
result
"""

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode reset_scene result"}
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

    # Ensure we have a valid scene and context
    if not bpy.context.scene:
        bpy.ops.scene.new(type='NEW')

    scene = bpy.context.scene
    objects = [obj.name for obj in scene.objects]

    # Safely get active object
    try:
        active_object = bpy.context.active_object
        active_object_name = active_object.name if active_object else None
    except AttributeError:
        active_object_name = None

    result = {
        "scene_name": scene.name,
        "frame_current": scene.frame_current,
        "frame_start": scene.frame_start,
        "frame_end": scene.frame_end,
        "fps": scene.render.fps,
        "fps_base": scene.render.fps_base,
        "objects": objects,
        "active_object": active_object_name
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
  Only executes when Pythonx/Blender is available and not in test mode.
  """
  @spec ensure_scene_fps() :: :ok
  defp ensure_scene_fps do
    # In test mode, never execute Python code
    if Mix.env() == :test do
      :ok
    else
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
    # In test mode, never try to execute Python code
    if Mix.env() == :test do
      :mock
    else
      # Test if both Pythonx works and bpy is available
      case Pythonx.eval("import bpy; 1 + 1", %{}) do
        {result, _globals} ->
          case Pythonx.decode(result) do
            2 -> :ok
            _ -> :mock
          end

        _ ->
          :mock
      end
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
  def test_mock_take_photo(filepath, camera_location, camera_rotation, focal_length, resolution_x, resolution_y), do: mock_take_photo(filepath, camera_location, camera_rotation, focal_length, resolution_x, resolution_y)
  @doc false
  def test_mock_get_scene_info(), do: mock_get_scene_info()
  @doc false
  def test_mock_reset_scene(), do: mock_reset_scene()
end
