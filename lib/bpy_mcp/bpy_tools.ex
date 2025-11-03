# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyTools do
  @moduledoc """
  Blender bpy tools exposed via MCP using Pythonx for 3D operations.

  This module provides a unified interface for all bpy operations, delegating
  to specialized submodules:
  - `BpyMcp.BpyTools.Objects` - Object creation (cubes, spheres)
  - `BpyMcp.BpyTools.Materials` - Material operations
  - `BpyMcp.BpyTools.Rendering` - Rendering operations
  - `BpyMcp.BpyTools.Scene` - Scene management
  - `BpyMcp.BpyTools.Introspection` - API introspection tools
  - `BpyMcp.BpyTools.Utils` - Shared utilities
  """

  alias BpyMcp.BpyTools.{Objects, Materials, Rendering, Scene, Introspection, Planning}

  @type bpy_result :: {:ok, term()} | {:error, String.t()}

  # Object creation functions
  @doc """
  Creates a cube object in the Blender scene.
  """
  @spec create_cube(String.t(), [number()], number(), String.t()) :: bpy_result()
  defdelegate create_cube(name \\ "Cube", location \\ [0, 0, 0], size \\ 2.0, temp_dir),
    to: Objects

@doc """
  Creates a sphere object in the Blender scene.
  """
  @spec create_sphere(String.t(), [number()], number(), String.t()) :: bpy_result()
  defdelegate create_sphere(name \\ "Sphere", location \\ [0, 0, 0], radius \\ 1.0, temp_dir),
    to: Objects

  # Material functions
  @doc """
Sets a material on an object.
"""
@spec set_material(String.t(), String.t(), [number()], String.t()) :: bpy_result()
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
@spec render_image(String.t(), integer(), integer(), String.t()) :: bpy_result()
  defdelegate render_image(
                filepath,
                resolution_x \\ 1920,
                resolution_y \\ 1080,
                temp_dir
              ),
              to: Rendering

  # Scene management functions
@doc """
Resets the Blender scene to a clean state by removing all objects.
"""
@spec reset_scene(String.t()) :: bpy_result()
  defdelegate reset_scene(temp_dir), to: Scene

@doc """
Gets information about the current Blender scene.
"""
@spec get_scene_info(String.t()) :: bpy_result()
  defdelegate get_scene_info(temp_dir), to: Scene

  # Introspection functions
  @doc """
  Introspects Blender bpy/bmesh structure for debugging and understanding API.
  """
  @spec introspect_bpy(String.t(), String.t()) :: bpy_result()
  defdelegate introspect_bpy(object_path \\ "bmesh", temp_dir), to: Introspection

  @doc """
  Introspects any Python object/API structure for debugging and understanding Python APIs.
  """
  @spec introspect_python(String.t(), String.t() | nil, String.t()) :: bpy_result()
  defdelegate introspect_python(object_path, prep_code \\ nil, temp_dir), to: Introspection

  # Planning functions
  @doc """
  Plans a scene construction workflow given initial and goal states.
  """
  @spec plan_scene_construction(map(), String.t()) :: bpy_result()
  defdelegate plan_scene_construction(plan_spec, temp_dir), to: Planning

  @doc """
  Plans material application sequence respecting dependencies.
  """
  @spec plan_material_application(map(), String.t()) :: bpy_result()
  defdelegate plan_material_application(plan_spec, temp_dir), to: Planning

  @doc """
  Plans animation sequence with temporal constraints.
  """
  @spec plan_animation(map(), String.t()) :: bpy_result()
  defdelegate plan_animation(plan_spec, temp_dir), to: Planning

  @doc """
  Executes a generated plan by calling bpy-mcp tools in sequence.
  """
  @spec execute_plan(String.t(), String.t()) :: bpy_result()
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
end
