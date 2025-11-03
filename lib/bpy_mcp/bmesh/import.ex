# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BMesh.Import do
  @moduledoc """
  BMesh import functionality for glTF with EXT_mesh_bmesh extension.
  """

  require Logger

  @type import_result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Imports BMesh data from glTF JSON with EXT_mesh_bmesh extension.
  """
  @spec import_gltf_scene(String.t(), String.t()) :: BpyMcp.BpyMesh.bpy_result()
  def import_gltf_scene(gltf_json, temp_dir) do
    case BpyMcp.BMesh.ensure_pythonx() do
      :ok ->
        do_import_gltf_scene(gltf_json, temp_dir)

      :mock ->
        BpyMcp.BMesh.Mock.import_gltf_scene(gltf_json)
    end
  end

  # Real Blender import implementation
  defp do_import_gltf_scene(gltf_json, temp_dir) do
    # Escape the JSON string for embedding in Python code
    escaped_json = gltf_json |> String.replace("\\", "\\\\") |> String.replace("'", "\\'")
    
    code = """
import bpy
import bmesh
import base64
import json
import struct

# Parse glTF JSON
gltf_json = '''#{escaped_json}'''
gltf_data = json.loads(gltf_json)
meshes = gltf_data.get('meshes', [])
imported_count = 0

for mesh_data in meshes:
    name = mesh_data.get('name', 'ImportedMesh')
    primitives = mesh_data.get('primitives', [])

    for primitive in primitives:
        ext_bmesh = primitive.get('extensions', {}).get('EXT_mesh_bmesh')
        if not ext_bmesh:
            continue

        # Create new mesh and object
        mesh = bpy.data.meshes.new(name)
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)

        # Get BMesh topology data
        vertices_data = ext_bmesh.get('vertices', {})
        edges_data = ext_bmesh.get('edges', {})
        faces_data = ext_bmesh.get('faces', {})
        loops_data = ext_bmesh.get('loops', {})

        # Extract vertex positions
        vertex_positions = vertices_data.get('positions', [])

        # Create BMesh
        bm = bmesh.new()

        # Add vertices first
        verts = []
        for pos in vertex_positions:
            vert = bm.verts.new(pos)
            verts.append(vert)
        bm.verts.ensure_lookup_table()
        bm.verts.index_update()

        # Build edge map for faster lookup
        edge_map = {}
        edge_vertices_list = edges_data.get('vertices', [])
        for i in range(0, len(edge_vertices_list), 2):
            v1_idx = edge_vertices_list[i]
            v2_idx = edge_vertices_list[i + 1]
            # Store edge by vertex pair (sorted for consistent lookup)
            edge_key = tuple(sorted([v1_idx, v2_idx]))
            if edge_key not in edge_map:
            v1 = bm.verts[v1_idx]
            v2 = bm.verts[v2_idx]
                edge = bm.edges.new([v1, v2])
                edge_map[edge_key] = edge
        
        bm.edges.ensure_lookup_table()
        bm.edges.index_update()

        # Create faces using bmesh.ops - this properly sets up loops
        face_vertices_list = faces_data.get('vertices', [])
        face_offsets = faces_data.get('offsets', [])

        if len(face_offsets) == 0:
            face_offsets = [0]

        # If we have proper offsets, use them to reconstruct faces
        if len(face_offsets) > 1:
        face_start = 0
        for face_end in face_offsets[1:]:
                face_vert_indices = face_vertices_list[face_start:face_end]
                if len(face_vert_indices) >= 3:  # Face needs at least 3 vertices
            face_verts = [bm.verts[i] for i in face_vert_indices]
                    # Use bmesh.ops to create face - this properly sets up all loops
                    try:
                        face = bm.faces.new(face_verts)
                        # Verify loops were created
                        if not face.loops:
                            # Fallback: manually create loops if needed
                            pass
                    except ValueError as e:
                        # Face creation failed (e.g., duplicate face)
                        print(f"Warning: Failed to create face with vertices {face_vert_indices}: {e}")
            face_start = face_end
        else:
            # Fallback: try to create faces from vertex list
            # This is a simple heuristic - assumes triangular faces
            for i in range(0, len(face_vertices_list) - 2, 3):
                try:
                    v1 = bm.verts[face_vertices_list[i]]
                    v2 = bm.verts[face_vertices_list[i + 1]]
                    v3 = bm.verts[face_vertices_list[i + 2]]
                    bm.faces.new([v1, v2, v3])
                except (ValueError, IndexError):
                    pass

        bm.faces.ensure_lookup_table()
        bm.faces.index_update()
        bm.loops.ensure_lookup_table()
        bm.loops.index_update()

        # Validate BMesh structure
        bm.verts.ensure_lookup_table()
        bm.edges.ensure_lookup_table()
        bm.faces.ensure_lookup_table()

        # Load BMesh into mesh
        bm.to_mesh(mesh)
        mesh.update()
        bm.free()

        imported_count += 1

result = f"Imported {imported_count} meshes with BMesh topology"
result
"""

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_binary(result) -> {:ok, result}
          _ -> {:error, "Failed to decode import result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end
end
