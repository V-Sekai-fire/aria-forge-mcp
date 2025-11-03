# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.BMesh.Binary do
  @moduledoc """
  Binary data encoding/decoding for EXT_mesh_bmesh format.
  """

  @doc """
  Reconstruct vertices from EXT_mesh_bmesh data (handles both formats).
  """
  @spec reconstruct_vertices(map(), list(), list(), list()) :: list()
  def reconstruct_vertices(ext_bmesh, accessors, bufferViews, buffers) do
    vertices_data = ext_bmesh["vertices"]
    positions = vertices_data["positions"]

    case positions do
      # If positions is an integer, it's an accessor index
      idx when is_integer(idx) ->
        reconstruct_vertices_from_accessors(ext_bmesh, accessors, bufferViews, buffers)

      # If positions is a list, it's direct data
      data when is_list(data) ->
        data
    end
  end

  @doc """
  Reconstruct edges from EXT_mesh_bmesh data (handles both formats).
  """
  @spec reconstruct_edges(map(), list(), list(), list()) :: list()
  def reconstruct_edges(ext_bmesh, accessors, bufferViews, buffers) do
    edges_data = ext_bmesh["edges"]
    vertices = edges_data["vertices"]

    case vertices do
      # If vertices is an integer, it's an accessor index
      idx when is_integer(idx) ->
        reconstruct_edges_from_accessors(ext_bmesh, accessors, bufferViews, buffers)

      # If vertices is a list, it's direct data
      data when is_list(data) ->
        reconstruct_edges_from_ext_bmesh(ext_bmesh)
    end
  end

  @doc """
  Reconstruct faces from EXT_mesh_bmesh data (handles both formats).
  """
  @spec reconstruct_faces(map(), list(), list(), list()) :: list()
  def reconstruct_faces(ext_bmesh, accessors, bufferViews, buffers) do
    faces_data = ext_bmesh["faces"]
    vertices = faces_data["vertices"]

    case vertices do
      # If vertices is an integer, it's an accessor index
      idx when is_integer(idx) ->
        reconstruct_faces_from_accessors(ext_bmesh, accessors, bufferViews, buffers)

      # If vertices is a list, it's direct data
      data when is_list(data) ->
        reconstruct_faces_from_ext_bmesh(ext_bmesh)
    end
  end

  @doc """
  Reconstruct edges from EXT_mesh_bmesh data.
  """
  @spec reconstruct_edges_from_ext_bmesh(map()) :: list()
  def reconstruct_edges_from_ext_bmesh(ext_bmesh) do
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

  @doc """
  Reconstruct faces from EXT_mesh_bmesh data.
  """
  @spec reconstruct_faces_from_ext_bmesh(map()) :: list()
  def reconstruct_faces_from_ext_bmesh(ext_bmesh) do
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

  @doc """
  Reconstruct vertices from EXT_mesh_bmesh accessor indices.
  """
  @spec reconstruct_vertices_from_accessors(map(), list(), list(), list()) :: list()
  def reconstruct_vertices_from_accessors(ext_bmesh, accessors, bufferViews, buffers) do
    vertices_data = ext_bmesh["vertices"]
    positions_accessor_idx = vertices_data["positions"]

    # Get the accessor
    accessor = Enum.at(accessors, positions_accessor_idx)
    buffer_view_idx = accessor["bufferView"]
    buffer_view = Enum.at(bufferViews, buffer_view_idx)
    buffer_idx = buffer_view["buffer"]
    buffer = Enum.at(buffers, buffer_idx)

    # Decode base64 data
    {:ok, binary_data} = Base.decode64(buffer["uri"] |> String.replace_prefix("data:application/octet-stream;base64,", ""))

    # Extract vertex positions (VEC3 of floats)
    count = accessor["count"]
    byte_offset = buffer_view["byteOffset"] + accessor["byteOffset"]

    for i <- 0..(count - 1) do
      # Each vertex is 3 floats (12 bytes)
      vertex_offset = byte_offset + (i * 12)
      <<x::float-32-little, y::float-32-little, z::float-32-little>> = binary_part(binary_data, vertex_offset, 12)
      [x, y, z]
    end
  end

  @doc """
  Reconstruct edges from EXT_mesh_bmesh accessor indices.
  """
  @spec reconstruct_edges_from_accessors(map(), list(), list(), list()) :: list()
  def reconstruct_edges_from_accessors(ext_bmesh, accessors, bufferViews, buffers) do
    edges_data = ext_bmesh["edges"]
    vertices_accessor_idx = edges_data["vertices"]
    count = edges_data["count"]

    # Get the accessor
    accessor = Enum.at(accessors, vertices_accessor_idx)
    buffer_view_idx = accessor["bufferView"]
    buffer_view = Enum.at(bufferViews, buffer_view_idx)
    buffer_idx = buffer_view["buffer"]
    buffer = Enum.at(buffers, buffer_idx)

    # Decode base64 data
    {:ok, binary_data} = Base.decode64(buffer["uri"] |> String.replace_prefix("data:application/octet-stream;base64,", ""))

    # Extract edge vertex pairs (pairs of unsigned shorts)
    byte_offset = buffer_view["byteOffset"] + accessor["byteOffset"]

    for i <- 0..(count - 1) do
      # Each edge is 2 unsigned shorts (4 bytes)
      edge_offset = byte_offset + (i * 4)
      <<v1::little-unsigned-16, v2::little-unsigned-16>> = binary_part(binary_data, edge_offset, 4)
      [v1, v2]
    end
  end

  @doc """
  Reconstruct faces from EXT_mesh_bmesh accessor indices.
  """
  @spec reconstruct_faces_from_accessors(map(), list(), list(), list()) :: list()
  def reconstruct_faces_from_accessors(ext_bmesh, accessors, bufferViews, buffers) do
    faces_data = ext_bmesh["faces"]
    vertices_accessor_idx = faces_data["vertices"]
    offsets_accessor_idx = faces_data["offsets"]
    count = faces_data["count"]

    # Get vertices accessor
    vertices_accessor = Enum.at(accessors, vertices_accessor_idx)
    vertices_buffer_view_idx = vertices_accessor["bufferView"]
    vertices_buffer_view = Enum.at(bufferViews, vertices_buffer_view_idx)
    vertices_buffer_idx = vertices_buffer_view["buffer"]
    vertices_buffer = Enum.at(buffers, vertices_buffer_idx)

    # Get offsets accessor
    offsets_accessor = Enum.at(accessors, offsets_accessor_idx)
    offsets_buffer_view_idx = offsets_accessor["bufferView"]
    offsets_buffer_view = Enum.at(bufferViews, offsets_buffer_view_idx)
    offsets_buffer_idx = offsets_buffer_view["buffer"]
    offsets_buffer = Enum.at(buffers, offsets_buffer_idx)

    # Decode vertices data
    {:ok, vertices_binary} = Base.decode64(vertices_buffer["uri"] |> String.replace_prefix("data:application/octet-stream;base64,", ""))
    vertices_byte_offset = vertices_buffer_view["byteOffset"] + vertices_accessor["byteOffset"]

    # Decode offsets data
    {:ok, offsets_binary} = Base.decode64(offsets_buffer["uri"] |> String.replace_prefix("data:application/octet-stream;base64,", ""))
    offsets_byte_offset = offsets_buffer_view["byteOffset"] + offsets_accessor["byteOffset"]

    # Extract face offsets
    face_offsets = for i <- 0..count do
      offset_pos = offsets_byte_offset + (i * 4)
      <<offset::little-unsigned-32>> = binary_part(offsets_binary, offset_pos, 4)
      offset
    end

    # Extract faces using offsets
    for i <- 0..(count - 1) do
      start_idx = Enum.at(face_offsets, i)
      end_idx = Enum.at(face_offsets, i + 1)
      face_size = end_idx - start_idx

      for j <- 0..(face_size - 1) do
        vertex_pos = vertices_byte_offset + ((start_idx + j) * 2)
        <<vertex_idx::little-unsigned-16>> = binary_part(vertices_binary, vertex_pos, 2)
        vertex_idx
      end
    end
  end
end
