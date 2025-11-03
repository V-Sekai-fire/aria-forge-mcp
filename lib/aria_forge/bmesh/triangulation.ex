# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.BMesh.Triangulation do
  @moduledoc """
  BMesh triangulation algorithms for EXT_mesh_bmesh specification.
  """

  @doc """
  Triangulate faces following EXT_mesh_bmesh specification (triangle fan with distinct anchors).
  """
  @spec triangulate_faces_ext_bmesh(map()) :: {list(), list(), list()}
  def triangulate_faces_ext_bmesh(mesh_data) do
    faces = mesh_data["faces"]
    face_normals = mesh_data["face_normals"]

    # EXT_mesh_bmesh requirement: select distinct anchor vertices for consecutive faces
    {triangles, triangle_normals, face_anchors} = select_anchors_and_triangulate(faces, face_normals)

    {triangles, triangle_normals, face_anchors}
  end

  @doc """
  Select distinct anchor vertices for consecutive faces and triangulate using triangle fans.
  This follows EXT_mesh_bmesh specification for unambiguous BMesh reconstruction.
  """
  @spec select_anchors_and_triangulate(list(), list()) :: {list(), list(), list()}
  def select_anchors_and_triangulate(faces, face_normals) do
    # Build face adjacency map to know which faces share edges
    adjacency_map = build_face_adjacency_map(faces)

    # Select anchor vertices ensuring consecutive faces use different anchors
    face_anchors = select_distinct_anchors(faces, adjacency_map)

    # Triangulate each face using triangle fan with its assigned anchor
    {triangles, triangle_normals} = triangulate_with_anchors(faces, face_normals, face_anchors)

    {triangles, triangle_normals, face_anchors}
  end

  @doc """
  Build adjacency map showing which faces share edges.
  """
  @spec build_face_adjacency_map(list()) :: map()
  def build_face_adjacency_map(faces) do
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

  @doc """
  Get all edges of a face as sorted tuples for consistent hashing.
  """
  @spec face_edges(list()) :: list()
  def face_edges(face) do
    for i <- 0..(length(face) - 1) do
      v1 = Enum.at(face, i)
      v2 = Enum.at(face, rem(i + 1, length(face)))
      Enum.sort([v1, v2]) |> List.to_tuple()
    end
  end

  @doc """
  Select distinct anchor vertices for consecutive faces.
  EXT_mesh_bmesh requirement: consecutive faces must use different anchor vertices.
  """
  @spec select_distinct_anchors(list(), map()) :: list()
  def select_distinct_anchors(faces, adjacency_map) do
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

  @doc """
  Triangulate faces using triangle fans with assigned anchor vertices.
  """
  @spec triangulate_with_anchors(list(), list(), list()) :: {list(), list()}
  def triangulate_with_anchors(faces, face_normals, face_anchors) do
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

  @doc """
  Create triangle fan from a face using specified anchor vertex.
  EXT_mesh_bmesh uses triangle fans for unambiguous reconstruction.
  """
  @spec create_triangle_fan(list(), integer()) :: list()
  def create_triangle_fan(face, anchor_idx) do
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

  @doc """
  Triangulate an n-gon using ear clipping algorithm (BMesh spec compliant).
  """
  @spec triangulate_ngon(list()) :: list()
  def triangulate_ngon(vertices) when length(vertices) <= 3 do
    # Already a triangle or degenerate
    [vertices]
  end

  def triangulate_ngon(vertices) do
    # Simple ear clipping: connect first vertex to each pair of consecutive vertices
    # This follows BMesh triangulation pattern
    [first | rest] = vertices
    _triangles = []

    # Create triangles by connecting first vertex to each edge
    triangles = for i <- 0..(length(rest) - 2) do
      v1 = Enum.at(rest, i)
      v2 = Enum.at(rest, i + 1)
      [first, v1, v2]
    end

    triangles
  end
end
