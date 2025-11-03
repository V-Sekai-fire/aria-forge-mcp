# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.BMesh.Export do
  @moduledoc """
  BMesh export functionality for various formats.
  """

  require Logger

  @type export_result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Exports BMesh data as JSON using a simple DSL.
  """
  @spec export_json(String.t(), map()) :: export_result
  def export_json(_temp_dir, opts \\ %{}) do
    # Python/bpy removed - use mock implementation only
    AriaForge.BMesh.Mock.export_json(opts)
  end

  @doc """
  Exports the current scene as complete glTF 2.0 JSON with EXT_mesh_bmesh extension.
  """
  @spec export_gltf_scene(String.t()) :: AriaForge.Mesh.result()
  def export_gltf_scene(_temp_dir) do
    # Python/bpy removed - use mock implementation only
    AriaForge.BMesh.Mock.export_gltf_scene()
  end

  # Removed Python/bpy implementation - now uses mock only
  # The following functions are kept for reference but not used
  defp _unused_extract_raw_bmesh_data(_temp_dir) do
    code = """
import bpy
import bmesh

# Get all mesh objects in the scene
mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']

meshes = []
for obj in mesh_objects:
    # Create BMesh from object
    bm = bmesh.new()
    bm.from_mesh(obj.data)

    # Ensure BMesh is in consistent state
    bm.verts.ensure_lookup_table()
    bm.edges.ensure_lookup_table()
    bm.faces.ensure_lookup_table()

    # Extract raw vertex data
    vertices = [[v.co.x, v.co.y, v.co.z] for v in bm.verts]

    # Extract raw edge data with connectivity
    edges = [[e.verts[0].index, e.verts[1].index] for e in bm.edges]

    # Extract raw face data (before triangulation - preserve n-gons)
    faces = [[vert.index for vert in face.verts] for face in bm.faces]

    # Extract loop data (face corners with UVs, normals, etc.)
    loops = []
    for face in bm.faces:
        for loop in face.loops:
            loop_data = {
                "vertex": loop.vert.index,
                "edge": loop.edge.index,
                "face": face.index
            }
            loops.append(loop_data)

    # Extract additional mesh properties
    mesh_data = {
        "name": obj.name,
        "vertices": vertices,
        "edges": edges,
        "faces": faces,
        "loops": loops,
        "vertex_normals": [[v.normal.x, v.normal.y, v.normal.z] for v in bm.verts],
        "face_normals": [[f.normal.x, f.normal.y, f.normal.z] for f in bm.faces],
        "vertex_groups": [list(v.groups.keys()) if v.groups else [] for v in bm.verts],
        "uv_layers": {},
        "materials": [slot.material.name if slot.material else None for slot in obj.data.materials],
        "custom_normals": [[l.normal.x, l.normal.y, l.normal.z] for face in bm.faces for l in face.loops],
        "crease_edges": [{"edge": e.index, "crease": e.crease} for e in bm.edges if e.crease > 0],
        "sharp_edges": [e.index for e in bm.edges if e.smooth == False],
        "face_materials": [f.material_index for f in bm.faces],
        "face_smooth": [f.smooth for f in bm.faces]
    }

    # Extract UV coordinates if available
    if bm.loops.layers.uv:
        uv_layer = bm.loops.layers.uv.active
        uvs = []
        for face in bm.faces:
            face_uvs = []
            for loop in face.loops:
                uv = loop[uv_layer].uv
                face_uvs.append([uv.x, uv.y])
            uvs.append(face_uvs)
        mesh_data["uv_layers"]["UVMap"] = uvs

    # Extract vertex colors if available
    if bm.loops.layers.color:
        color_layer = bm.loops.layers.color.active
        vertex_colors = []
        for face in bm.faces:
            face_colors = []
            for loop in face.loops:
                color = loop[color_layer]
                face_colors.append([color.x, color.y, color.z, color.w])
            vertex_colors.append(face_colors)
        mesh_data["vertex_colors"] = vertex_colors

    meshes.append(mesh_data)

    # Clean up
    bm.free()

result = {"meshes": meshes}
result
"""

    case Pythonx.eval(code, %{"working_directory" => _temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_map(result) -> {:ok, result}
          _ -> {:error, "Failed to decode raw BMesh data"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end

  defp _unused_do_export_gltf_scene(_temp_dir) do
    code = """
import bpy
import bmesh
import base64
import struct

# Get all mesh objects in the scene
mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']

if not mesh_objects:
    result = {
        "asset": {"version": "2.0", "generator": "AriaForge BMesh Exporter"},
        "scene": 0,
        "scenes": [{"nodes": []}],
        "nodes": [],
        "meshes": [],
        "accessors": [],
        "bufferViews": [],
        "buffers": []
    }
else:
    all_buffers = []
    all_buffer_views = []
    all_accessors = []
    meshes = []
    nodes = []
    buffer_offset = 0

    for i, obj in enumerate(mesh_objects):
        # Create BMesh from object
        bm = bmesh.new()
        bm.from_mesh(obj.data)

        # Ensure BMesh is in consistent state
        bmesh.ops.triangulate(bm, faces=bm.faces)
        bm.verts.ensure_lookup_table()
        bm.edges.ensure_lookup_table()
        bm.faces.ensure_lookup_table()

        # Extract vertices and normals
        vertices = []
        normals = []
        for vert in bm.verts:
            vertices.extend([vert.co.x, vert.co.y, vert.co.z])
            # Calculate vertex normal (average of connected face normals)
            normal = [0, 0, 0]
            for face in vert.link_faces:
                normal[0] += face.normal.x
                normal[1] += face.normal.y
                normal[2] += face.normal.z
            length = (normal[0]**2 + normal[1]**2 + normal[2]**2)**0.5
            if length > 0:
                normal = [normal[0]/length, normal[1]/length, normal[2]/length]
            normals.extend(normal)

        # Create indices
        indices = []
        for face in bm.faces:
            for vert in face.verts:
                indices.append(vert.index)

        # Convert to binary data
        vertex_data = struct.pack('<' + 'f' * len(vertices), *vertices)
        normal_data = struct.pack('<' + 'f' * len(normals), *normals)
        index_data = struct.pack('<' + 'H' * len(indices), *indices)

        # Create buffers
        vertex_buffer = {
            "byteLength": len(vertex_data),
            "uri": "data:application/octet-stream;base64," + base64.b64encode(vertex_data).decode('ascii')
        }
        normal_buffer = {
            "byteLength": len(normal_data),
            "uri": "data:application/octet-stream;base64," + base64.b64encode(normal_data).decode('ascii')
        }
        index_buffer = {
            "byteLength": len(index_data),
            "uri": "data:application/octet-stream;base64," + base64.b64encode(index_data).decode('ascii')
        }

        vertex_buffer_idx = len(all_buffers)
        normal_buffer_idx = len(all_buffers) + 1
        index_buffer_idx = len(all_buffers) + 2

        all_buffers.extend([vertex_buffer, normal_buffer, index_buffer])

        # Create buffer views
        vertex_buffer_view = {
            "buffer": vertex_buffer_idx,
            "byteOffset": 0,
            "byteLength": len(vertex_data),
            "target": 34962  # ARRAY_BUFFER
        }
        normal_buffer_view = {
            "buffer": normal_buffer_idx,
            "byteOffset": 0,
            "byteLength": len(normal_data),
            "target": 34962  # ARRAY_BUFFER
        }
        index_buffer_view = {
            "buffer": index_buffer_idx,
            "byteOffset": 0,
            "byteLength": len(index_data),
            "target": 34963  # ELEMENT_ARRAY_BUFFER
        }

        vertex_bv_idx = len(all_buffer_views)
        normal_bv_idx = len(all_buffer_views) + 1
        index_bv_idx = len(all_buffer_views) + 2

        all_buffer_views.extend([vertex_buffer_view, normal_buffer_view, index_buffer_view])

        # Calculate min/max for vertices
        vertex_positions = []
        for j in range(0, len(vertices), 3):
            vertex_positions.append([vertices[j], vertices[j+1], vertices[j+2]])
        min_vals = [min(p[0] for p in vertex_positions), min(p[1] for p in vertex_positions), min(p[2] for p in vertex_positions)]
        max_vals = [max(p[0] for p in vertex_positions), max(p[1] for p in vertex_positions), max(p[2] for p in vertex_positions)]

        # Create accessors
        position_accessor = {
            "bufferView": vertex_bv_idx,
            "byteOffset": 0,
            "componentType": 5126,  # FLOAT
            "count": len(vertex_positions),
            "type": "VEC3",
            "min": min_vals,
            "max": max_vals
        }
        normal_accessor = {
            "bufferView": normal_bv_idx,
            "byteOffset": 0,
            "componentType": 5126,  # FLOAT
            "count": len(vertex_positions),
            "type": "VEC3"
        }
        index_accessor = {
            "bufferView": index_bv_idx,
            "byteOffset": 0,
            "componentType": 5123,  # UNSIGNED_SHORT
            "count": len(indices),
            "type": "SCALAR",
            "min": [min(indices)] if indices else [0],
            "max": [max(indices)] if indices else [0]
        }

        position_acc_idx = len(all_accessors)
        normal_acc_idx = len(all_accessors) + 1
        index_acc_idx = len(all_accessors) + 2

        all_accessors.extend([position_accessor, normal_accessor, index_accessor])

        # Extract BMesh topology data for EXT_mesh_bmesh
        bmesh_vertices = []
        for vert in bm.verts:
            bmesh_vertices.append([vert.co.x, vert.co.y, vert.co.z])

        edge_vertices = []
        for edge in bm.edges:
            edge_vertices.extend([edge.verts[0].index, edge.verts[1].index])

        edge_faces = []
        edge_faces_offsets = [0]
        for edge in bm.edges:
            connected_faces = [face.index for face in edge.link_faces]
            edge_faces.extend(connected_faces)
            edge_faces_offsets.append(len(edge_faces))

        loop_vertex_indices = []
        loop_edge_indices = []
        loop_face_indices = []
        loop_next_indices = []
        loop_prev_indices = []
        loop_radial_next_indices = []
        loop_radial_prev_indices = []

        edge_loop_map = {}
        for edge in bm.edges:
            edge_loop_map[edge.index] = [loop.index for loop in edge.link_loops]

        loop_index = 0
        for face in bm.faces:
            face_loop_start = loop_index
            face_loop_count = len(face.loops)

            for j, loop in enumerate(face.loops):
                loop_vertex_indices.append(loop.vert.index)
                loop_edge_indices.append(loop.edge.index)
                loop_face_indices.append(face.index)

                next_idx = face_loop_start + (j + 1) % face_loop_count
                prev_idx = face_loop_start + (j - 1) % face_loop_count
                loop_next_indices.append(next_idx)
                loop_prev_indices.append(prev_idx)

                edge_loops = edge_loop_map[loop.edge.index]
                current_pos = edge_loops.index(loop.index)
                radial_next_pos = (current_pos + 1) % len(edge_loops)
                radial_prev_pos = (current_pos - 1) % len(edge_loops)

                loop_radial_next_indices.append(edge_loops[radial_next_pos])
                loop_radial_prev_indices.append(edge_loops[radial_prev_pos])

                loop_index += 1

        face_vertices = []
        face_edges = []
        face_loops = []
        face_offsets = [0]

        for face in bm.faces:
            face_vertices.extend([vert.index for vert in face.verts])
            face_edges.extend([edge.index for edge in face.edges])
            face_loops.extend([loop.index for loop in face.loops])
            face_offsets.append(len(face_vertices))

        # Create mesh with EXT_mesh_bmesh extension
        mesh_data = {
            "name": obj.name,
            "primitives": [{
                "attributes": {
                    "POSITION": position_acc_idx,
                    "NORMAL": normal_acc_idx
                },
                "indices": index_acc_idx,
                "mode": 4,  # TRIANGLES
                "extensions": {
                    "EXT_mesh_bmesh": {
                        "vertices": {
                            "count": len(bmesh_vertices),
                            "positions": bmesh_vertices
                        },
                        "edges": {
                            "count": len(bm.edges),
                            "vertices": edge_vertices,
                            "faces": edge_faces,
                            "offsets": edge_faces_offsets
                        },
                        "loops": {
                            "count": len(loop_vertex_indices),
                            "topology_vertex": loop_vertex_indices,
                            "topology_edge": loop_edge_indices,
                            "topology_face": loop_face_indices,
                            "topology_next": loop_next_indices,
                            "topology_prev": loop_prev_indices,
                            "topology_radial_next": loop_radial_next_indices,
                            "topology_radial_prev": loop_radial_prev_indices
                        },
                        "faces": {
                            "count": len(bm.faces),
                            "vertices": face_vertices,
                            "edges": face_edges,
                            "loops": face_loops,
                            "offsets": face_offsets
                        }
                    }
                }
            }]
        }

        meshes.append(mesh_data)

        # Extract transform
        translation = [obj.location.x, obj.location.y, obj.location.z]
        rotation = [obj.rotation_quaternion.x, obj.rotation_quaternion.y, obj.rotation_quaternion.z, obj.rotation_quaternion.w]
        scale = [obj.scale.x, obj.scale.y, obj.scale.z]

        node_data = {
            "name": obj.name,
            "mesh": i,
            "translation": translation,
            "rotation": rotation,
            "scale": scale
        }

        nodes.append(node_data)

        # Clean up
        bm.free()

    # Create complete glTF structure
    result = {
        "asset": {
            "version": "2.0",
            "generator": "AriaForge BMesh Exporter"
        },
        "scene": 0,
        "scenes": [{"nodes": list(range(len(nodes)))}],
        "nodes": nodes,
        "meshes": meshes,
        "accessors": all_accessors,
        "bufferViews": all_buffer_views,
        "buffers": all_buffers,
        "extensionsUsed": ["EXT_mesh_bmesh"]
    }

result
"""

    case Pythonx.eval(code, %{"working_directory" => _temp_dir}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          result when is_map(result) -> {:ok, result}
          _ -> {:error, "Failed to decode glTF export result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e ->
      {:error, Exception.message(e)}
  end
end
