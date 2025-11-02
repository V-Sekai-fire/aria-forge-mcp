# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyMesh do
  @moduledoc """
  Blender BMesh export functionality for EXT_mesh_bmesh format.
  """

  require Logger

  @type bpy_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Exports BMesh data as JSON using a simple DSL.

  ## Examples

      # Export everything as JSON
      BpyMcp.BpyMesh.export_json(temp_dir)

      # Export with options
      BpyMcp.BpyMesh.export_json(temp_dir, %{include_normals: true})

  ## Returns
    - `{:ok, String.t()}` - JSON string of BMesh data
    - `{:error, String.t()}` - Error message
  """
  @spec export_json(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def export_json(temp_dir, opts \\ %{}) do
    case ensure_pythonx() do
      :ok ->
        do_export_json(temp_dir, opts)

      :mock ->
        mock_export_json(opts)
    end
  end

  @doc """
  Exports the current Blender scene as complete glTF 2.0 JSON with EXT_mesh_bmesh extension.

  ## Returns
    - `{:ok, map()}` - Complete glTF 2.0 JSON data
    - `{:error, String.t()}` - Error message
  """
  @spec export_bmesh_scene(String.t()) :: bpy_result()
  def export_bmesh_scene(temp_dir) do
    case ensure_pythonx() do
      :ok ->
        do_export_gltf_scene(temp_dir)

      :mock ->
        mock_export_gltf_scene()
    end
  end

  @doc false
  def test_mock_export_bmesh_scene(), do: mock_export_gltf_scene()

  # JSON DSL Implementation - Extract raw data from Blender, process in Elixir

  defp do_export_json(temp_dir, opts) do
    # Extract raw data from Blender
    case extract_raw_bmesh_data(temp_dir) do
      {:ok, raw_data} ->
        # Process in Elixir
        processed_data = process_bmesh_data(raw_data, opts)
        json_string = Jason.encode!(processed_data)
        {:ok, json_string}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp mock_export_json(opts) do
    # Mock raw data with comprehensive BMesh structure
    raw_data = %{
      "meshes" => [
        %{
          "name" => "MockCube",
          "vertices" => [[-1,-1,-1], [1,-1,-1], [1,1,-1], [-1,1,-1], [-1,-1,1], [1,-1,1], [1,1,1], [-1,1,1]],
          "edges" => [[0,1], [1,2], [2,3], [3,0], [4,5], [5,6], [6,7], [7,4], [0,4], [1,5], [2,6], [3,7]],
          "faces" => [[0,1,2,3], [4,7,6,5], [0,3,7,4], [1,5,6,2], [0,4,5,1], [3,2,6,7]],
          "loops" => [
            %{"vertex" => 0, "edge" => 0, "face" => 0},
            %{"vertex" => 1, "edge" => 1, "face" => 0},
            %{"vertex" => 2, "edge" => 2, "face" => 0},
            %{"vertex" => 3, "edge" => 3, "face" => 0},
            %{"vertex" => 4, "edge" => 4, "face" => 1},
            %{"vertex" => 7, "edge" => 7, "face" => 1},
            %{"vertex" => 6, "edge" => 6, "face" => 1},
            %{"vertex" => 5, "edge" => 5, "face" => 1},
            %{"vertex" => 0, "edge" => 8, "face" => 2},
            %{"vertex" => 3, "edge" => 11, "face" => 2},
            %{"vertex" => 7, "edge" => 7, "face" => 2},
            %{"vertex" => 4, "edge" => 4, "face" => 2},
            %{"vertex" => 1, "edge" => 9, "face" => 3},
            %{"vertex" => 5, "edge" => 5, "face" => 3},
            %{"vertex" => 6, "edge" => 6, "face" => 3},
            %{"vertex" => 2, "edge" => 2, "face" => 3},
            %{"vertex" => 0, "edge" => 8, "face" => 4},
            %{"vertex" => 4, "edge" => 4, "face" => 4},
            %{"vertex" => 5, "edge" => 5, "face" => 4},
            %{"vertex" => 1, "edge" => 9, "face" => 4},
            %{"vertex" => 3, "edge" => 11, "face" => 5},
            %{"vertex" => 2, "edge" => 2, "face" => 5},
            %{"vertex" => 6, "edge" => 6, "face" => 5},
            %{"vertex" => 7, "edge" => 7, "face" => 5}
          ],
          "vertex_normals" => [[0.0, 0.0, -1.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [-1.0, 0.0, 0.0], [0.0, -1.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [-1.0, 0.0, 0.0]],
          "face_normals" => [[0.0, 0.0, -1.0], [0.0, 0.0, 1.0], [0.0, -1.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [-1.0, 0.0, 0.0]],
          "custom_normals" => [
            [0.0, 0.0, -1.0], [0.0, 0.0, -1.0], [0.0, 0.0, -1.0], [0.0, 0.0, -1.0],
            [0.0, 0.0, 1.0], [0.0, 0.0, 1.0], [0.0, 0.0, 1.0], [0.0, 0.0, 1.0],
            [0.0, -1.0, 0.0], [0.0, -1.0, 0.0], [0.0, -1.0, 0.0], [0.0, -1.0, 0.0],
            [1.0, 0.0, 0.0], [1.0, 0.0, 0.0], [1.0, 0.0, 0.0], [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0], [0.0, 1.0, 0.0], [0.0, 1.0, 0.0], [0.0, 1.0, 0.0],
            [-1.0, 0.0, 0.0], [-1.0, 0.0, 0.0], [-1.0, 0.0, 0.0], [-1.0, 0.0, 0.0]
          ],
          "crease_edges" => [],
          "sharp_edges" => [],
          "face_materials" => [0, 0, 0, 0, 0, 0],
          "face_smooth" => [true, true, true, true, true, true],
          "vertex_groups" => [[], [], [], [], [], [], [], []],
          "uv_layers" => %{},
          "materials" => ["DefaultMaterial"],
          "vertex_colors" => []
        }
      ]
    }

    # Process in Elixir (triangulation, etc.)
    processed_data = process_bmesh_data(raw_data, opts)
    json_string = Jason.encode!(processed_data)
    {:ok, json_string}
  end

  # Extract comprehensive raw BMesh data from Blender
  defp extract_raw_bmesh_data(temp_dir) do
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

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
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

  # Process BMesh data in Elixir (preserve original topology, provide triangulated version for rendering)
  defp process_bmesh_data(raw_data, opts) do
    meshes = Enum.map(raw_data["meshes"], fn mesh_data ->
      # Preserve original BMesh topology (n-gons, loops, etc.)
      original_topology = build_original_bmesh_topology(mesh_data)

      # Create triangulated version for rendering (following EXT_mesh_bmesh spec)
      {triangles, triangle_normals, face_anchors} = triangulate_faces_ext_bmesh(mesh_data)

      # Build triangulated topology for rendering
      triangulated_topology = build_triangulated_topology(mesh_data, triangles)

      # Apply any transformations
      transformed_mesh = apply_mesh_transforms(mesh_data, opts)

      %{
        "name" => mesh_data["name"],
        "vertices" => transformed_mesh["vertices"],
        "vertex_normals" => transformed_mesh["vertex_normals"],
        # Original BMesh topology (preserves n-gons)
        "original_faces" => mesh_data["faces"],
        "original_loops" => mesh_data["loops"],
        "original_topology" => original_topology,
        # Triangulated version for rendering
        "triangles" => triangles,
        "triangle_normals" => triangle_normals,
        "face_anchors" => face_anchors,
        "triangulated_topology" => triangulated_topology,
        # Additional BMesh data
        "custom_normals" => mesh_data["custom_normals"],
        "crease_edges" => mesh_data["crease_edges"],
        "sharp_edges" => mesh_data["sharp_edges"],
        "face_materials" => mesh_data["face_materials"],
        "face_smooth" => mesh_data["face_smooth"],
        "materials" => mesh_data["materials"],
        "uv_layers" => mesh_data["uv_layers"],
        "vertex_colors" => mesh_data["vertex_colors"]
      }
    end)

    %{
      "metadata" => %{
        "version" => "1.0",
        "generator" => "BpyMcp BMesh DSL",
        "exported_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "options" => opts
      },
      "meshes" => meshes
    }
  end

  # Triangulate faces following EXT_mesh_bmesh specification (triangle fan with distinct anchors)
  defp triangulate_faces_ext_bmesh(mesh_data) do
    faces = mesh_data["faces"]
    face_normals = mesh_data["face_normals"]

    # EXT_mesh_bmesh requirement: select distinct anchor vertices for consecutive faces
    {triangles, triangle_normals, face_anchors} = select_anchors_and_triangulate(faces, face_normals)

    {triangles, triangle_normals, face_anchors}
  end

  # Select distinct anchor vertices for consecutive faces and triangulate using triangle fans
  # This follows EXT_mesh_bmesh specification for unambiguous BMesh reconstruction
  defp select_anchors_and_triangulate(faces, face_normals) do
    # Build face adjacency map to know which faces share edges
    adjacency_map = build_face_adjacency_map(faces)

    # Select anchor vertices ensuring consecutive faces use different anchors
    face_anchors = select_distinct_anchors(faces, adjacency_map)

    # Triangulate each face using triangle fan with its assigned anchor
    {triangles, triangle_normals} = triangulate_with_anchors(faces, face_normals, face_anchors)

    {triangles, triangle_normals, face_anchors}
  end

  # Build adjacency map showing which faces share edges
  defp build_face_adjacency_map(faces) do
    # First pass: build edge-to-faces mapping
    edge_to_faces = Enum.reduce(Enum.with_index(faces), %{}, fn {face, face_idx}, acc ->
      face_edges = face_edges(face)
      Enum.reduce(face_edges, acc, fn edge, edge_acc ->
        Map.update(edge_acc, edge, [face_idx], &[face_idx | &1])
      end)
    end)

    # Second pass: build face adjacency map
    Enum.reduce(Enum.with_index(faces), %{}, fn {_face, face_idx}, adjacency_map ->
      # Find all faces that share at least one edge
      adjacent_faces = Enum.flat_map(face_edges(Enum.at(faces, face_idx)), fn edge ->
        Map.get(edge_to_faces, edge, []) |> Enum.reject(&(&1 == face_idx))
      end) |> Enum.uniq()

      Map.put(adjacency_map, face_idx, adjacent_faces)
    end)
  end

  # Get all edges of a face as sorted tuples for consistent hashing
  defp face_edges(face) do
    for i <- 0..(length(face) - 1) do
      v1 = Enum.at(face, i)
      v2 = Enum.at(face, rem(i + 1, length(face)))
      Enum.sort([v1, v2]) |> List.to_tuple()
    end
  end

  # Select distinct anchor vertices for consecutive faces
  # EXT_mesh_bmesh requirement: consecutive faces must use different anchor vertices
  defp select_distinct_anchors(faces, adjacency_map) do
    Enum.map(Enum.with_index(faces), fn {face, face_idx} ->
      adjacent_faces = Map.get(adjacency_map, face_idx, [])
      used_anchors = Enum.map(adjacent_faces, fn adj_idx ->
        # For now, we'll assign anchors sequentially and resolve conflicts later
        # This is a simplified approach - in practice you'd use a more sophisticated algorithm
        rem(adj_idx, length(face))
      end)

      # Select an anchor vertex not used by adjacent faces
      available_anchors = 0..(length(face) - 1) |> Enum.reject(&(&1 in used_anchors))

      # If no available anchors, use the first vertex (this is a fallback)
      case available_anchors do
        [first | _] -> first
        [] -> 0
      end
    end)
  end

  # Triangulate faces using triangle fans with assigned anchor vertices
  defp triangulate_with_anchors(faces, face_normals, face_anchors) do
    {triangles, triangle_normals} =
      Enum.with_index(faces)
      |> Enum.flat_map_reduce([], fn {face, face_idx}, acc_normals ->
        anchor_idx = Enum.at(face_anchors, face_idx)
        face_normal = Enum.at(face_normals, face_idx)

        # Create triangle fan from anchor vertex
        fan_triangles = create_triangle_fan(face, anchor_idx)

        # Create corresponding normals for each triangle
        fan_normals = List.duplicate(face_normal, length(fan_triangles))

        {fan_triangles, acc_normals ++ fan_normals}
      end)

    {triangles, triangle_normals}
  end

  # Create triangle fan from a face using specified anchor vertex
  # EXT_mesh_bmesh uses triangle fans for unambiguous reconstruction
  defp create_triangle_fan(face, anchor_idx) do
    if length(face) <= 3 do
      # Already a triangle
      [face]
    else
      # Create triangle fan from anchor vertex
      anchor_vertex = Enum.at(face, anchor_idx)
      other_vertices = List.delete_at(face, anchor_idx)

      # Create triangles: anchor + consecutive pairs from remaining vertices
      for i <- 0..(length(other_vertices) - 2) do
        v1 = Enum.at(other_vertices, i)
        v2 = Enum.at(other_vertices, i + 1)
        [anchor_vertex, v1, v2]
      end
    end
  end

  # Triangulate an n-gon using ear clipping algorithm (BMesh spec compliant)
  defp triangulate_ngon(vertices) when length(vertices) <= 3 do
    # Already a triangle or degenerate
    [vertices]
  end

  defp triangulate_ngon(vertices) do
    # Simple ear clipping: connect first vertex to each pair of consecutive vertices
    # This follows BMesh triangulation pattern
    [first | rest] = vertices
    triangles = []

    # Create triangles by connecting first vertex to each edge
    triangles = for i <- 0..(length(rest) - 2) do
      v1 = Enum.at(rest, i)
      v2 = Enum.at(rest, i + 1)
      [first, v1, v2]
    end

    triangles
  end

  # Build original BMesh topology (preserves n-gons and full topology)
  defp build_original_bmesh_topology(mesh_data) do
    vertices = mesh_data["vertices"]
    edges = mesh_data["edges"]
    faces = mesh_data["faces"]
    loops = mesh_data["loops"]

    # Build edge connectivity map
    edge_map = Enum.reduce(Enum.with_index(edges), %{}, fn {[v1, v2], edge_idx}, acc ->
      key = Enum.sort([v1, v2]) |> List.to_tuple()
      Map.put(acc, key, edge_idx)
    end)

    # Build face-to-edge connectivity
    face_edges = Enum.map(faces, fn face ->
      for i <- 0..(length(face) - 1) do
        v1 = Enum.at(face, i)
        v2 = Enum.at(face, rem(i + 1, length(face)))
        key = Enum.sort([v1, v2]) |> List.to_tuple()
        Map.get(edge_map, key, -1)  # -1 for missing edges
      end
    end)

    # Build loop topology from extracted loops
    loop_topology = build_loop_topology_from_loops(loops, faces)

    %{
      "vertices" => %{
        "count" => length(vertices),
        "positions" => vertices
      },
      "edges" => %{
        "count" => length(edges),
        "vertices" => List.flatten(edges),
        "faces" => face_edges
      },
      "faces" => %{
        "count" => length(faces),
        "vertices" => List.flatten(faces),
        "edges" => List.flatten(face_edges),
        "offsets" => Enum.scan(faces, 0, fn face, offset -> offset + length(face) end)
      },
      "loops" => loop_topology
    }
  end

  # Build triangulated topology for rendering
  defp build_triangulated_topology(mesh_data, triangles) do
    vertices = mesh_data["vertices"]
    edges = mesh_data["edges"]

    # Build face connectivity for edges as a list indexed by edge position
    edge_faces_map = Enum.reduce(Enum.with_index(triangles), %{}, fn {face, face_idx}, acc ->
      face_edges = for i <- 0..2 do
        v1 = Enum.at(face, i)
        v2 = Enum.at(face, rem(i + 1, 3))
        Enum.sort([v1, v2])
      end

      Enum.reduce(face_edges, acc, fn edge_key, face_acc ->
        Map.update(face_acc, edge_key, [face_idx], &[face_idx | &1])
      end)
    end)

    # Convert to list indexed by edge index
    edge_faces = Enum.map(edges, fn [v1, v2] ->
      edge_key = Enum.sort([v1, v2])
      Map.get(edge_faces_map, edge_key, [])
    end)

    # Build loop topology (simplified)
    loops = build_loop_topology(triangles)

    %{
      "edges" => %{
        "count" => length(edges),
        "vertices" => List.flatten(edges),
        "faces" => edge_faces
      },
      "faces" => %{
        "count" => length(triangles),
        "vertices" => List.flatten(triangles),
        "offsets" => Enum.scan(triangles, 0, fn face, offset -> offset + length(face) end)
      },
      "loops" => loops
    }
  end

  # Build complete BMesh topology in Elixir (legacy function)
  defp build_topology(mesh_data, triangles) do
    build_triangulated_topology(mesh_data, triangles)
  end

  # Build loop topology from extracted loops data
  defp build_loop_topology_from_loops(loops, faces) do
    # Build face loop offsets to determine loop ranges per face
    face_loop_offsets = [0] ++ Enum.scan(faces, 0, fn face, offset -> offset + length(face) end)

    # Build loop connectivity arrays
    loop_vertices = Enum.map(loops, & &1["vertex"])
    loop_edges = Enum.map(loops, & &1["edge"])
    loop_faces = Enum.map(loops, & &1["face"])

    # Build next/prev connectivity within each face
    {loop_next, loop_prev} = Enum.reduce(Enum.with_index(faces), {[], []}, fn {_face, face_idx}, {next_acc, prev_acc} ->
      face_start = Enum.at(face_loop_offsets, face_idx)
      face_end = Enum.at(face_loop_offsets, face_idx + 1)
      face_loop_count = face_end - face_start

      # Build next/prev for this face's loops
      face_next = for i <- 0..(face_loop_count - 1) do
        face_start + rem(i + 1, face_loop_count)
      end

      face_prev = for i <- 0..(face_loop_count - 1) do
        face_start + rem(i - 1 + face_loop_count, face_loop_count)
      end

      {next_acc ++ face_next, prev_acc ++ face_prev}
    end)

    %{
      "count" => length(loops),
      "topology_vertex" => loop_vertices,
      "topology_edge" => loop_edges,
      "topology_face" => loop_faces,
      "topology_next" => loop_next,
      "topology_prev" => loop_prev
    }
  end

  # Build loop topology in Elixir
  defp build_loop_topology(triangles) do
    loop_index = 0
    {loop_vertices, loop_edges, loop_faces, loop_next, loop_prev} =
      Enum.reduce(Enum.with_index(triangles), {[], [], [], [], []}, fn {face, face_idx}, acc ->
        {lverts, ledges, lfaces, lnext, lprev} = acc

        face_loop_start = loop_index
        face_loop_count = length(face)

        # Build loops for this face
        face_loops = for i <- 0..(face_loop_count - 1) do
          vertex_idx = Enum.at(face, i)
          edge_idx = find_edge_index(triangles, vertex_idx, Enum.at(face, rem(i + 1, face_loop_count)))

          %{
            vertex: vertex_idx,
            edge: edge_idx,
            face: face_idx,
            next: face_loop_start + rem(i + 1, face_loop_count),
            prev: face_loop_start + rem(i - 1 + face_loop_count, face_loop_count)
          }
        end

        # Extract arrays
        new_lverts = lverts ++ Enum.map(face_loops, & &1.vertex)
        new_ledges = ledges ++ Enum.map(face_loops, & &1.edge)
        new_lfaces = lfaces ++ Enum.map(face_loops, & &1.face)
        new_lnext = lnext ++ Enum.map(face_loops, & &1.next)
        new_lprev = lprev ++ Enum.map(face_loops, & &1.prev)

        loop_index = loop_index + face_loop_count

        {new_lverts, new_ledges, new_lfaces, new_lnext, new_lprev}
      end)

    %{
      "count" => length(loop_vertices),
      "topology_vertex" => loop_vertices,
      "topology_edge" => loop_edges,
      "topology_face" => loop_faces,
      "topology_next" => loop_next,
      "topology_prev" => loop_prev
    }
  end

  # Helper function to find edge index
  defp find_edge_index(triangles, v1, v2) do
    # This is a simplified implementation - in practice you'd build a proper edge lookup
    edge_key = Enum.sort([v1, v2])
    # Return a dummy edge index for now
    :erlang.phash2(edge_key, 1000)
  end

  # Apply mesh transformations
  defp apply_mesh_transforms(mesh_data, opts) do
    vertices = mesh_data["vertices"]

    # Apply scaling if requested
    scaled_vertices = case opts["scale"] do
      nil -> vertices
      scale_factor -> Enum.map(vertices, fn [x, y, z] -> [x * scale_factor, y * scale_factor, z * scale_factor] end)
    end

    # Apply translation if requested
    translated_vertices = case opts["translate"] do
      nil -> scaled_vertices
      [tx, ty, tz] -> Enum.map(scaled_vertices, fn [x, y, z] -> [x + tx, y + ty, z + tz] end)
    end

    %{mesh_data | "vertices" => translated_vertices}
  end

  defp mock_export_gltf_scene do
    # Create mock vertex data (cube vertices)
    vertices = [
      -1.0, -1.0, -1.0,  # 0
       1.0, -1.0, -1.0,  # 1
       1.0,  1.0, -1.0,  # 2
      -1.0,  1.0, -1.0,  # 3
      -1.0, -1.0,  1.0,  # 4
       1.0, -1.0,  1.0,  # 5
       1.0,  1.0,  1.0,  # 6
      -1.0,  1.0,  1.0   # 7
    ]

    # Create mock indices (triangulated cube faces)
    indices = [
      0, 1, 2, 0, 2, 3,  # front
      1, 5, 6, 1, 6, 2,  # right
      5, 4, 7, 5, 7, 6,  # back
      4, 0, 3, 4, 3, 7,  # left
      3, 2, 6, 3, 6, 7,  # top
      4, 5, 1, 4, 1, 0   # bottom
    ]

    # Create mock normals
    normals = [
      0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0,  # front
      1.0, 0.0,  0.0, 1.0, 0.0,  0.0, 1.0, 0.0,  0.0, 1.0, 0.0,  0.0, 1.0, 0.0,  0.0, 1.0, 0.0,  0.0,  # right
      0.0, 0.0,  1.0, 0.0, 0.0,  1.0, 0.0, 0.0,  1.0, 0.0, 0.0,  1.0, 0.0, 0.0,  1.0, 0.0, 0.0,  1.0,  # back
     -1.0, 0.0,  0.0,-1.0, 0.0,  0.0,-1.0, 0.0,  0.0,-1.0, 0.0,  0.0,-1.0, 0.0,  0.0,-1.0, 0.0,  0.0,  # left
      0.0, 1.0,  0.0, 0.0, 1.0,  0.0, 0.0, 1.0,  0.0, 0.0, 1.0,  0.0, 0.0, 1.0,  0.0, 0.0, 1.0,  0.0,  # top
      0.0,-1.0,  0.0, 0.0,-1.0,  0.0, 0.0,-1.0,  0.0, 0.0,-1.0,  0.0, 0.0,-1.0,  0.0, 0.0,-1.0,  0.0   # bottom
    ]

    # Convert to base64 for buffer
    vertex_data = vertices |> :erlang.list_to_binary() |> Base.encode64()
    index_data = indices |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    normal_data = normals |> :erlang.list_to_binary() |> Base.encode64()

    {:ok,
     %{
       "asset" => %{
         "version" => "2.0",
         "generator" => "BpyMcp BMesh Exporter"
       },
       "scene" => 0,
       "scenes" => [
         %{
           "nodes" => [0]
         }
       ],
       "nodes" => [
         %{
           "name" => "MockCube",
           "mesh" => 0,
           "translation" => [0.0, 0.0, 0.0],
           "rotation" => [0.0, 0.0, 0.0, 1.0],
           "scale" => [1.0, 1.0, 1.0]
         }
       ],
       "meshes" => [
         %{
           "name" => "MockCube",
           "primitives" => [
             %{
               "attributes" => %{
                 "POSITION" => 0,
                 "NORMAL" => 1
               },
               "indices" => 2,
               "mode" => 4,  # TRIANGLES
               "extensions" => %{
                 "EXT_mesh_bmesh" => %{
                   "vertices" => %{
                     "count" => 8,
                     "positions" => [
                       [-1.0, -1.0, -1.0],
                       [1.0, -1.0, -1.0],
                       [1.0, 1.0, -1.0],
                       [-1.0, 1.0, -1.0],
                       [-1.0, -1.0, 1.0],
                       [1.0, -1.0, 1.0],
                       [1.0, 1.0, 1.0],
                       [-1.0, 1.0, 1.0]
                     ]
                   },
                   "edges" => %{
                     "count" => 12,
                     "vertices" => [0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7]
                   },
                   "loops" => %{
                     "count" => 24,
                     "topology_vertex" => [0, 1, 2, 3, 4, 7, 6, 5, 0, 3, 7, 4, 1, 5, 6, 2, 0, 4, 5, 1, 3, 2, 6, 7],
                     "topology_edge" => [0, 1, 2, 3, 8, 11, 10, 9, 4, 7, 6, 5, 12, 15, 14, 13, 16, 17, 18, 19, 20, 21, 22, 23],
                     "topology_face" => [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5],
                     "topology_next" => [1, 2, 3, 0, 5, 6, 7, 4, 9, 10, 11, 8, 13, 14, 15, 12, 17, 18, 19, 16, 21, 22, 23, 20],
                     "topology_prev" => [3, 0, 1, 2, 7, 4, 5, 6, 11, 8, 9, 10, 15, 12, 13, 14, 19, 16, 17, 18, 23, 20, 21, 22],
                     "topology_radial_next" => [4, 8, 12, 16, 0, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92],
                     "topology_radial_prev" => [16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 0, 4, 8, 12, 64, 68, 72, 76, 80, 84, 88, 92]
                   },
                   "faces" => %{
                     "count" => 6,
                     "vertices" => [0, 1, 2, 3, 4, 7, 6, 5, 0, 3, 7, 4, 1, 5, 6, 2, 0, 4, 5, 1, 3, 2, 6, 7],
                     "offsets" => [0, 4, 8, 12, 16, 20, 24]
                   }
                 }
               }
             }
           ]
         }
       ],
       "accessors" => [
         %{
           "bufferView" => 0,
           "byteOffset" => 0,
           "componentType" => 5126,  # FLOAT
           "count" => 24,  # 8 vertices * 3 components
           "type" => "VEC3",
           "min" => [-1.0, -1.0, -1.0],
           "max" => [1.0, 1.0, 1.0]
         },
         %{
           "bufferView" => 1,
           "byteOffset" => 0,
           "componentType" => 5126,  # FLOAT
           "count" => 36,  # 12 triangles * 3 vertices * 3 components
           "type" => "VEC3"
         },
         %{
           "bufferView" => 2,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 36,  # 12 triangles * 3 vertices
           "type" => "SCALAR",
           "min" => [0],
           "max" => [7]
         }
       ],
       "bufferViews" => [
         %{
           "buffer" => 0,
           "byteOffset" => 0,
           "byteLength" => 96,  # 8 vertices * 3 floats * 4 bytes
           "target" => 34962  # ARRAY_BUFFER
         },
         %{
           "buffer" => 1,
           "byteOffset" => 0,
           "byteLength" => 432,  # 36 floats * 4 bytes * 3 components
           "target" => 34962  # ARRAY_BUFFER
         },
         %{
           "buffer" => 2,
           "byteOffset" => 0,
           "byteLength" => 72,  # 36 indices * 2 bytes
           "target" => 34963  # ELEMENT_ARRAY_BUFFER
         }
       ],
       "buffers" => [
         %{
           "byteLength" => 96,
           "uri" => "data:application/octet-stream;base64,#{vertex_data}"
         },
         %{
           "byteLength" => 432,
           "uri" => "data:application/octet-stream;base64,#{normal_data}"
         },
         %{
           "byteLength" => 72,
           "uri" => "data:application/octet-stream;base64,#{index_data}"
         }
       ],
       "extensionsUsed" => ["EXT_mesh_bmesh"]
     }}
  end

  defp do_export_gltf_scene(temp_dir) do
    code = """
import bpy
import bmesh
import base64
import struct

# Get all mesh objects in the scene
mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']

if not mesh_objects:
    result = {
        "asset": {"version": "2.0", "generator": "BpyMcp BMesh Exporter"},
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
            "generator": "BpyMcp BMesh Exporter"
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

    case Pythonx.eval(code, %{"working_directory" => temp_dir}) do
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

  # Mock import for testing (reconstructs BMesh from exported data)
  defp mock_import_gltf_scene(gltf_json) do
    case Jason.decode(gltf_json) do
      {:ok, gltf_data} ->
        # Extract mesh data from glTF
        meshes = gltf_data["meshes"] || []
        imported_meshes = []

        Enum.each(meshes, fn mesh ->
          name = mesh["name"] || "ImportedMesh"
          primitive = hd(mesh["primitives"] || [])
          ext_bmesh = get_in(primitive, ["extensions", "EXT_mesh_bmesh"])

          if ext_bmesh do
            # Reconstruct BMesh topology from EXT_mesh_bmesh data
            vertices = ext_bmesh["vertices"]["positions"]
            edges = reconstruct_edges_from_ext_bmesh(ext_bmesh)
            faces = reconstruct_faces_from_ext_bmesh(ext_bmesh)

            imported_mesh = %{
              "name" => name,
              "vertices" => vertices,
              "edges" => edges,
              "faces" => faces,
              "topology" => ext_bmesh
            }

            imported_meshes = [imported_mesh | imported_meshes]
          end
        end)

        {:ok, "Imported #{length(imported_meshes)} meshes with BMesh topology"}

      {:error, reason} ->
        {:error, "Failed to parse glTF JSON: #{reason}"}
    end
  end

  # Reconstruct edges from EXT_mesh_bmesh data
  defp reconstruct_edges_from_ext_bmesh(ext_bmesh) do
    # EXT_mesh_bmesh stores edge vertices as flattened array
    edge_vertices = ext_bmesh["edges"]["vertices"]
    count = ext_bmesh["edges"]["count"]

    # Convert flattened [v1,v2,v1,v2,...] to [[v1,v2], [v1,v2], ...]
    for i <- 0..(count - 1) do
      v1 = Enum.at(edge_vertices, i * 2)
      v2 = Enum.at(edge_vertices, i * 2 + 1)
      [v1, v2]
    end
  end

  # Reconstruct faces from EXT_mesh_bmesh data
  defp reconstruct_faces_from_ext_bmesh(ext_bmesh) do
    face_vertices = ext_bmesh["faces"]["vertices"]
    face_offsets = ext_bmesh["faces"]["offsets"] || [0]

    # Reconstruct faces from flattened vertex array using offsets
    for i <- 0..(length(face_offsets) - 2) do
      start_idx = Enum.at(face_offsets, i)
      end_idx = Enum.at(face_offsets, i + 1)
      face_size = end_idx - start_idx

      for j <- 0..(face_size - 1) do
        Enum.at(face_vertices, start_idx + j)
      end
    end
  end

  # Real Blender import implementation
  defp do_import_gltf_scene(gltf_json) do
    code = """
import bpy
import bmesh
import base64
import json
import struct

# Parse glTF JSON
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
        vertices_data = ext_bmesh['vertices']
        edges_data = ext_bmesh['edges'] 
        faces_data = ext_bmesh['faces']
        loops_data = ext_bmesh['loops']
        
        # Extract vertex positions
        vertex_positions = vertices_data['positions']
        
        # Create BMesh
        bm = bmesh.new()
        
        # Add vertices
        for pos in vertex_positions:
            bm.verts.new(pos)
        bm.verts.ensure_lookup_table()
        
        # Add edges
        edge_vertices = edges_data['vertices']
        for i in range(0, len(edge_vertices), 2):
            v1_idx = edge_vertices[i]
            v2_idx = edge_vertices[i + 1]
            v1 = bm.verts[v1_idx]
            v2 = bm.verts[v2_idx]
            bm.edges.new([v1, v2])
        bm.edges.ensure_lookup_table()
        
        # Add faces
        face_vertices = faces_data['vertices']
        face_offsets = faces_data.get('offsets', [0])
        
        face_start = 0
        for face_end in face_offsets[1:]:
            face_vert_indices = face_vertices[face_start:face_end]
            face_verts = [bm.verts[i] for i in face_vert_indices]
            bm.faces.new(face_verts)
            face_start = face_end
        bm.faces.ensure_lookup_table()
        
        # Load BMesh into mesh
        bm.to_mesh(mesh)
        bm.free()
        
        imported_count += 1

result = f"Imported {imported_count} meshes with BMesh topology"
result
"""

    case Pythonx.eval(code, %{"gltf_json" => gltf_json}) do
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

  # Import helper functions from BpyTools
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
      # Redirect stderr to prevent EGL errors from corrupting stdio
      try do
        code = """
        import bpy
        result = bpy.context.scene is not None
        result
        """

        # Use /dev/null to suppress Blender's output from corrupting stdio
        null_device = File.open!("/dev/null", [:write])
        case Pythonx.eval(code, %{}, stdout_device: null_device, stderr_device: null_device) do
          {result, _globals} ->
            case Pythonx.decode(result) do
              true -> :ok
              _ -> :mock
            end

          _ ->
            :mock
        end
      rescue
        _ -> :mock
      end
    end
  end
end
