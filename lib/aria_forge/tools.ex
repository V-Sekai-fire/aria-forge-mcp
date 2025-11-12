# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools do
  @moduledoc """
  tools exposed via MCP using Pythonx for 3D operations.

  This module provides a unified interface for all scene operations, delegating
  to specialized submodules:
  - `AriaForge.Tools.Objects` - Object creation (cubes, spheres)
  - `AriaForge.Tools.Materials` - Material operations
  - `AriaForge.Tools.Rendering` - Rendering operations
  - `AriaForge.Tools.Scene` - Scene management
  - `AriaForge.Tools.Introspection` - API introspection tools
  - `AriaForge.Tools.Utils` - Shared utilities
  """

  alias AriaForge.Tools.{Objects, Materials, Rendering, Scene, Introspection, Planning, Animation}

  @type result :: {:ok, term()} | {:error, String.t()}

  # Object creation functions
  @doc """
  Creates a cube object in the scene.
  """
  @spec create_cube(String.t(), [number()], number(), String.t()) :: result()
  defdelegate create_cube(name \\ "Cube", location \\ [0, 0, 0], size \\ 2.0, temp_dir),
    to: Objects

  @doc """
  Creates a sphere object in the scene.
  """
  @spec create_sphere(String.t(), [number()], number(), String.t()) :: result()
  defdelegate create_sphere(name \\ "Sphere", location \\ [0, 0, 0], radius \\ 1.0, temp_dir),
    to: Objects

  # Material functions
  @doc """
  Sets a material on an object.
  """
  @spec set_material(String.t(), String.t(), [number()], String.t()) :: result()
  defdelegate set_material(
                object_name,
                material_name \\ "Material",
                color \\ [0.8, 0.8, 0.8, 1.0],
                temp_dir
              ),
              to: Materials

  # Rendering functions
  @doc """
  Renders the current scene to an image file.
  """
  @spec render_image(String.t(), integer(), integer(), String.t()) :: result()
  defdelegate render_image(
                filepath,
                resolution_x \\ 1920,
                resolution_y \\ 1080,
                temp_dir
              ),
              to: Rendering

  # Scene management functions
  @doc """
  Resets the scene to a clean state by removing all objects.
  """
  @spec reset_scene(String.t()) :: result()
  defdelegate reset_scene(temp_dir), to: Scene

  @doc """
  Gets information about the current scene.
  """
  @spec get_scene_info(String.t()) :: result()
  defdelegate get_scene_info(temp_dir), to: Scene

  @doc """
  Sets the scene frame rate (FPS).
  """
  @spec set_scene_fps(integer(), String.t()) :: result()
  defdelegate set_scene_fps(fps \\ 30, temp_dir), to: Scene

  # Introspection functions
  @doc """
  Introspects bpy/bmesh structure for debugging and understanding API.
  """
  @spec introspect_blender(String.t(), String.t()) :: result()
  defdelegate introspect_blender(object_path \\ "bmesh", temp_dir), to: Introspection

  @doc """
  Introspects any Python object/API structure for debugging and understanding Python APIs.
  """
  @spec introspect_python(String.t(), String.t() | nil, String.t()) :: result()
  defdelegate introspect_python(object_path, prep_code \\ nil, temp_dir), to: Introspection

  # Planning functions
  @doc """
  Plans a scene construction workflow given initial and goal states.
  """
  @spec plan_scene_construction(map(), String.t()) :: result()
  defdelegate plan_scene_construction(plan_spec, temp_dir), to: Planning

  @doc """
  Plans material application sequence respecting dependencies.
  """
  @spec plan_material_application(map(), String.t()) :: result()
  defdelegate plan_material_application(plan_spec, temp_dir), to: Planning

  @doc """
  Plans animation sequence with temporal constraints.
  """
  @spec plan_animation(map(), String.t()) :: result()
  defdelegate plan_animation(plan_spec, temp_dir), to: Planning

  @doc """
  Executes a generated plan by calling aria-forge tools in sequence.
  """
  @spec execute_plan(String.t(), String.t()) :: result()
  defdelegate execute_plan(plan_data, temp_dir), to: Planning

  # Test helper functions for backward compatibility
  @doc false
  def test_mock_create_cube(name, location, size),
    do: Objects.test_mock_create_cube(name, location, size)

  @doc false
  def test_mock_create_sphere(name, location, radius),
    do: Objects.test_mock_create_sphere(name, location, radius)

  @doc false
  def test_mock_set_material(object_name, material_name, color),
    do: Materials.test_mock_set_material(object_name, material_name, color)

  @doc false
  def test_mock_render_image(filepath, resolution_x, resolution_y),
    do: Rendering.test_mock_render_image(filepath, resolution_x, resolution_y)

  @doc false
  def test_mock_get_scene_info(), do: Scene.test_mock_get_scene_info()

  @doc false
  def test_mock_reset_scene(), do: Scene.test_mock_reset_scene()

  @doc false
  def test_mock_set_scene_fps(fps), do: Scene.test_mock_set_scene_fps(fps)
end
