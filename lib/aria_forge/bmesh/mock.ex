# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.BMesh.Mock do
  @moduledoc """
  Mock data and test implementations for BMesh functionality.
  """

  @doc """
  Mock export JSON implementation.
  """
  @spec export_json(map()) :: {:ok, String.t()}
  def export_json(opts) do
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
    processed_data = AriaForge.BMesh.Topology.process_bmesh_data(raw_data, opts)
    json_string = Jason.encode!(processed_data)
    {:ok, json_string}
  end

  @doc """
  Mock export glTF scene implementation.
  """
  @spec export_gltf_scene() :: {:ok, map()}
  def export_gltf_scene do
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
      0.0,-1.0,  0.0, 0.0,-1.0,  0.0, 0.0,-1.0,  0.0, 0.0,-1.0, 0.0, 0.0,-1.0,  0.0, 0.0,-1.0,  0.0   # bottom
    ]

    # EXT_mesh_bmesh data - following proper specification with accessor indices
    # BMesh vertex positions (same as regular vertices for this simple case)
    bmesh_positions = vertices

    # BMesh edges as pairs of vertex indices
    bmesh_edges = [0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7]

    # Edge faces connectivity (which faces share each edge)
    bmesh_edge_faces = [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5]

    # Loop topology data
    topology_vertex = [0, 1, 2, 3, 4, 7, 6, 5, 0, 3, 7, 4, 1, 5, 6, 2, 0, 4, 5, 1, 3, 2, 6, 7]
    topology_edge = [0, 1, 2, 3, 8, 11, 10, 9, 4, 7, 6, 5, 12, 15, 14, 13, 16, 17, 18, 19, 20, 21, 22, 23]
    topology_face = [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5]
    topology_next = [1, 2, 3, 0, 5, 6, 7, 4, 9, 10, 11, 8, 13, 14, 15, 12, 17, 18, 19, 16, 21, 22, 23, 20]
    topology_prev = [3, 0, 1, 2, 7, 4, 5, 6, 11, 8, 9, 10, 15, 12, 13, 14, 19, 16, 17, 18, 23, 20, 21, 22]
    topology_radial_next = [4, 8, 12, 16, 0, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92]
    topology_radial_prev = [16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 0, 4, 8, 12, 64, 68, 72, 76, 80, 84, 88, 92]

    # Face data
    face_vertices = [0, 1, 2, 3, 4, 7, 6, 5, 0, 3, 7, 4, 1, 5, 6, 2, 0, 4, 5, 1, 3, 2, 6, 7]
    face_edges = [0, 1, 2, 3, 8, 11, 10, 9, 4, 7, 6, 5, 12, 15, 14, 13, 16, 17, 18, 19, 20, 21, 22, 23]
    face_loops = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]
    face_offsets = [0, 4, 8, 12, 16, 20, 24]

    # Convert all data to base64 buffers
    vertex_data = vertices |> Enum.map(&<<&1::float-32-little>>) |> :erlang.list_to_binary() |> Base.encode64()
    index_data = indices |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    normal_data = normals |> Enum.map(&<<&1::float-32-little>>) |> :erlang.list_to_binary() |> Base.encode64()

    # EXT_mesh_bmesh buffers
    bmesh_positions_data = bmesh_positions |> Enum.map(&<<&1::float-32-little>>) |> :erlang.list_to_binary() |> Base.encode64()
    bmesh_edges_data = bmesh_edges |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    bmesh_edge_faces_data = bmesh_edge_faces |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    topology_vertex_data = topology_vertex |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    topology_edge_data = topology_edge |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    topology_face_data = topology_face |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    topology_next_data = topology_next |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    topology_prev_data = topology_prev |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    topology_radial_next_data = topology_radial_next |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    topology_radial_prev_data = topology_radial_prev |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    face_vertices_data = face_vertices |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    face_edges_data = face_edges |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    face_loops_data = face_loops |> Enum.map(&<<&1::little-unsigned-16>>) |> :erlang.list_to_binary() |> Base.encode64()
    face_offsets_data = face_offsets |> Enum.map(&<<&1::little-unsigned-32>>) |> :erlang.list_to_binary() |> Base.encode64()

    {:ok,
     %{
       "asset" => %{
         "version" => "2.0",
         "generator" => "AriaForge BMesh Exporter"
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
                     "attributes" => %{
                       "POSITION" => 3
                    },
                    "positions" => 3
                   },
                   "edges" => %{
                     "count" => 12,
                    "faces" => 5,
                    "offsets" => 16,
                    "vertices" => 4
                   },
                   "loops" => %{
                     "count" => 24,
                    "topology_edge" => 7,
                    "topology_face" => 8,
                    "topology_next" => 9,
                    "topology_prev" => 10,
                    "topology_radial_next" => 11,
                    "topology_radial_prev" => 12,
                    "topology_vertex" => 6
                   },
                   "faces" => %{
                     "count" => 6,
                    "edges" => 14,
                    "loops" => 15,
                    "offsets" => 16,
                    "vertices" => 13
                   }
                 }
               }
             }
           ]
         }
       ],
       "accessors" => [
         # Regular glTF accessors
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
         },
         # EXT_mesh_bmesh accessors
         %{
           "bufferView" => 3,
           "byteOffset" => 0,
           "componentType" => 5126,  # FLOAT
           "count" => 8,  # 8 vertices
           "type" => "VEC3"
         },
         %{
           "bufferView" => 4,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # 12 edges * 2 vertices
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 5,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # 12 edges * 2 faces (some may be -1)
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 6,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # 24 loops
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 7,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # 24 loops
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 8,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # 24 loops
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 9,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # 24 loops
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 10,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # 24 loops
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 11,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # 24 loops
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 12,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # 24 loops
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 13,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # face vertices
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 14,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # face edges
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 15,
           "byteOffset" => 0,
           "componentType" => 5123,  # UNSIGNED_SHORT
           "count" => 24,  # face loops
           "type" => "SCALAR"
         },
         %{
           "bufferView" => 16,
           "byteOffset" => 0,
           "componentType" => 5125,  # UNSIGNED_INT
           "count" => 7,  # face offsets
           "type" => "SCALAR"
         }
       ],
       "bufferViews" => [
         # Regular glTF buffer views
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
         },
         # EXT_mesh_bmesh buffer views
         %{
           "buffer" => 3,
           "byteOffset" => 0,
           "byteLength" => 96,  # 8 vertices * 3 floats * 4 bytes
           "target" => 34962
         },
         %{
           "buffer" => 4,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 edge vertices * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 5,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 edge faces * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 6,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 topology_vertex * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 7,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 topology_edge * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 8,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 topology_face * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 9,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 topology_next * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 10,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 topology_prev * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 11,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 topology_radial_next * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 12,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 topology_radial_prev * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 13,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 face_vertices * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 14,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 face_edges * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 15,
           "byteOffset" => 0,
           "byteLength" => 48,  # 24 face_loops * 2 bytes
           "target" => 34962
         },
         %{
           "buffer" => 16,
           "byteOffset" => 0,
           "byteLength" => 28,  # 7 face_offsets * 4 bytes
           "target" => 34962
         }
       ],
       "buffers" => [
         # Regular glTF buffers
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
         },
         # EXT_mesh_bmesh buffers
         %{
           "byteLength" => 96,
           "uri" => "data:application/octet-stream;base64,#{bmesh_positions_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{bmesh_edges_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{bmesh_edge_faces_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{topology_vertex_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{topology_edge_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{topology_face_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{topology_next_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{topology_prev_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{topology_radial_next_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{topology_radial_prev_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{face_vertices_data}"
         },
         %{
           "buffer" => 14,
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{face_edges_data}"
         },
         %{
           "byteLength" => 48,
           "uri" => "data:application/octet-stream;base64,#{face_loops_data}"
         },
         %{
           "byteLength" => 28,
           "uri" => "data:application/octet-stream;base64,#{face_offsets_data}"
         }
       ],
       "extensionsUsed" => ["EXT_mesh_bmesh"]
     }}
  end

  @doc """
  Mock import glTF scene implementation.
  """
  @spec import_gltf_scene(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def import_gltf_scene(gltf_json) do
    case Jason.decode(gltf_json) do
      {:ok, gltf_data} ->
        # Extract mesh data from glTF
        meshes = gltf_data["meshes"] || []
        _accessors = gltf_data["accessors"] || []
        _bufferViews = gltf_data["bufferViews"] || []
        _buffers = gltf_data["buffers"] || []
        imported_meshes = []

        imported_meshes = Enum.reduce(meshes, imported_meshes, fn mesh, acc ->
          name = mesh["name"] || "ImportedMesh"
          primitives = mesh["primitives"] || []

          Enum.reduce(primitives, acc, fn primitive, prim_acc ->
            extensions = primitive["extensions"] || %{}
            ext_bmesh = extensions["EXT_mesh_bmesh"]

            if ext_bmesh do
              # Count as imported even if reconstruction fails
              [name | prim_acc]
            else
              prim_acc
            end
          end)
        end)

        {:ok, "Imported #{length(imported_meshes)} meshes with BMesh topology"}

      {:error, %Jason.DecodeError{} = reason} ->
        {:error, "Failed to parse glTF JSON: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "Failed to parse glTF JSON: #{reason}"}
    end
  end
end
