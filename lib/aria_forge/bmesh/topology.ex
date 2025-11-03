# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.BMesh.Topology do
  @moduledoc """
  BMesh topology building and reconstruction functions.
  """

  @doc """
  Process BMesh data in Elixir (preserve original topology, provide triangulated version for rendering).
  """
  @spec process_bmesh_data(map(), map()) :: map()
  def process_bmesh_data(raw_data, opts) do
    meshes = Enum.map(raw_data["meshes"], fn mesh_data ->
      # Preserve original BMesh topology (n-gons, loops, etc.)
      original_topology = build_original_bmesh_topology(mesh_data)

      # Create triangulated version for rendering (following EXT_mesh_bmesh spec)
      {triangles, triangle_normals, face_anchors} = AriaForge.BMesh.Triangulation.triangulate_faces_ext_bmesh(mesh_data)

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
        "generator" => "AriaForge BMesh DSL",
        "exported_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "options" => opts
      },
      "meshes" => meshes
    }
  end

  @doc """
  Build original BMesh topology (preserves n-gons and full topology).
  """
  @spec build_original_bmesh_topology(map()) :: map()
  def build_original_bmesh_topology(mesh_data) do
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

  @doc """
  Build triangulated topology for rendering.
  """
  @spec build_triangulated_topology(map(), list()) :: map()
  def build_triangulated_topology(mesh_data, triangles) do
    _vertices = mesh_data["vertices"]
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

  @doc """
  Build loop topology from extracted loops data.
  """
  @spec build_loop_topology_from_loops(list(), list()) :: map()
  def build_loop_topology_from_loops(loops, faces) do
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

  @doc """
  Build loop topology in Elixir.
  """
  @spec build_loop_topology(list()) :: map()
  def build_loop_topology(triangles) do
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

        _loop_index = loop_index + face_loop_count

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

  @doc """
  Helper function to find edge index.
  """
  @spec find_edge_index(list(), integer(), integer()) :: integer()
  def find_edge_index(_triangles, v1, v2) do
    # This is a simplified implementation - in practice you'd build a proper edge lookup
    edge_key = Enum.sort([v1, v2])
    # Return a dummy edge index for now
    :erlang.phash2(edge_key, 1000)
  end

  @doc """
  Apply mesh transformations.
  """
  @spec apply_mesh_transforms(map(), map()) :: map()
  def apply_mesh_transforms(mesh_data, opts) do
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
end
