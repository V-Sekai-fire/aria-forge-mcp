# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Mesh do
  @moduledoc """
  BMesh export/import functionality for EXT_mesh_bmesh format.

  This module provides high-level functions for BMesh operations, delegating
  to specialized submodules for specific functionality.
  """

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Exports BMesh data as JSON using a simple DSL.

  ## Examples

      # Export everything as JSON
      AriaForge.Mesh.export_json(temp_dir)

      # Export with options
      AriaForge.Mesh.export_json(temp_dir, %{include_normals: true})

  ## Returns
    - `{:ok, String.t()}` - JSON string of BMesh data
    - `{:error, String.t()}` - Error message
  """
  @spec export_json(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def export_json(temp_dir, opts \\ %{}) do
    AriaForge.BMesh.Export.export_json(temp_dir, opts)
  end

  @doc """
  Exports the current scene as complete glTF 2.0 JSON with EXT_mesh_bmesh extension.

  ## Returns
    - `{:ok, map()}` - Complete glTF 2.0 JSON data
    - `{:error, String.t()}` - Error message
  """
  @spec export_bmesh_scene(String.t()) :: result()
  def export_bmesh_scene(temp_dir) do
    AriaForge.BMesh.Export.export_gltf_scene(temp_dir)
  end

  @doc """
  Imports BMesh data from glTF JSON with EXT_mesh_bmesh extension.

  ## Parameters
    - gltf_json: String containing glTF JSON data with EXT_mesh_bmesh extension
    - temp_dir: Temporary directory for context

  ## Returns
    - `{:ok, String.t()}` - Success message with import details
    - `{:error, String.t()}` - Error message
  """
  @spec import_bmesh_scene(String.t(), String.t()) :: result()
  def import_bmesh_scene(gltf_json, temp_dir) do
    AriaForge.BMesh.Import.import_gltf_scene(gltf_json, temp_dir)
  end

  @doc false
  def test_mock_export_bmesh_scene(), do: AriaForge.BMesh.Mock.export_gltf_scene()

  @doc false
  def test_reconstruct_vertices_from_accessors(ext_bmesh, accessors, bufferViews, buffers) do
    AriaForge.BMesh.Binary.reconstruct_vertices_from_accessors(ext_bmesh, accessors, bufferViews, buffers)
  end

  @doc false
  def test_reconstruct_edges_from_accessors(ext_bmesh, accessors, bufferViews, buffers) do
    AriaForge.BMesh.Binary.reconstruct_edges_from_accessors(ext_bmesh, accessors, bufferViews, buffers)
  end

  @doc false
  def test_reconstruct_faces_from_accessors(ext_bmesh, accessors, bufferViews, buffers) do
    AriaForge.BMesh.Binary.reconstruct_faces_from_accessors(ext_bmesh, accessors, bufferViews, buffers)
  end

  @doc false
  def ensure_pythonx do
    AriaForge.BMesh.ensure_pythonx()
  end
end
