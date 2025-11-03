defmodule BpyMcp.BpyMeshTest do
  use ExUnit.Case, async: true

  describe "export_json/2" do
    test "exports mock data successfully" do
      result = BpyMcp.BpyMesh.export_json("/tmp", %{})

      assert {:ok, json_string} = result
      assert is_binary(json_string)

      # Parse the JSON to verify structure
      data = Jason.decode!(json_string)

      assert Map.has_key?(data, "metadata")
      assert Map.has_key?(data, "meshes")
      assert length(data["meshes"]) > 0

      mesh = List.first(data["meshes"])
      assert Map.has_key?(mesh, "triangles")
      assert Map.has_key?(mesh, "face_anchors")
      assert Map.has_key?(mesh, "triangle_normals")
    end

    test "includes triangulation data in exported mesh" do
      result = BpyMcp.BpyMesh.export_json("/tmp", %{})
      assert {:ok, json_string} = result

      data = Jason.decode!(json_string)
      mesh = List.first(data["meshes"])

      # Check that triangulation produced the expected structure
      triangles = mesh["triangles"]
      face_anchors = mesh["face_anchors"]
      triangle_normals = mesh["triangle_normals"]

      # Mock cube has 6 quad faces, each producing 2 triangles = 12 triangles
      assert length(triangles) == 12
      assert length(face_anchors) == 6  # One anchor per original face
      assert length(triangle_normals) == 12  # One normal per triangle

      # Each triangle should have 3 vertices
      assert Enum.all?(triangles, fn triangle -> length(triangle) == 3 end)

      # Each face anchor should be a valid index for that face
      # (This is a basic sanity check - the actual EXT_mesh_bmesh compliance
      # would require more detailed validation)
      assert Enum.all?(face_anchors, fn anchor -> is_integer(anchor) and anchor >= 0 end)
    end
  end

  describe "import_bmesh_scene/2" do
    test "imports mock glTF data successfully" do
      # First export some data to get valid glTF JSON
      {:ok, gltf_data} = BpyMcp.BpyMesh.export_bmesh_scene("/tmp")

      # Convert to JSON string
      gltf_json = Jason.encode!(gltf_data)

      # Now import it back
      result = BpyMcp.BpyMesh.import_bmesh_scene(gltf_json, "/tmp")

      assert {:ok, message} = result
      assert is_binary(message)
      assert String.contains?(message, "Imported")
      assert String.contains?(message, "meshes")
    end

    test "handles invalid JSON gracefully" do
      result = BpyMcp.BpyMesh.import_bmesh_scene("invalid json", "/tmp")

      assert {:error, message} = result
      assert is_binary(message)
    end

    test "handles glTF without EXT_mesh_bmesh extension" do
      # Create minimal glTF without EXT_mesh_bmesh
      gltf_data = %{
        "asset" => %{"version" => "2.0"},
        "meshes" => [
          %{
            "name" => "TestMesh",
            "primitives" => [
              %{
                "attributes" => %{"POSITION" => 0},
                "indices" => 1
              }
            ]
          }
        ]
      }

      gltf_json = Jason.encode!(gltf_data)
      result = BpyMcp.BpyMesh.import_bmesh_scene(gltf_json, "/tmp")

      # Should succeed but import 0 meshes since no EXT_mesh_bmesh data
      assert {:ok, message} = result
      assert String.contains?(message, "Imported 0 meshes")
    end
  end

  describe "round-trip export/import" do
    test "export then import preserves mesh structure" do
      # Export mock scene
      {:ok, exported_gltf} = BpyMcp.BpyMesh.export_bmesh_scene("/tmp")

      # Convert to JSON and back
      gltf_json = Jason.encode!(exported_gltf)
      {:ok, import_message} = BpyMcp.BpyMesh.import_bmesh_scene(gltf_json, "/tmp")

      # Verify import succeeded
      assert String.contains?(import_message, "Imported")
      assert String.contains?(import_message, "meshes")

      # Extract mesh count from message
      imported_count = extract_mesh_count(import_message)
      exported_count = length(exported_gltf["meshes"] || [])

      # Should import the same number of meshes that were exported
      assert imported_count == exported_count
    end

    test "EXT_mesh_bmesh topology reconstruction" do
      # Export mock scene
      {:ok, exported_gltf} = BpyMcp.BpyMesh.export_bmesh_scene("/tmp")

      # Get the EXT_mesh_bmesh data from the first mesh
      first_mesh = List.first(exported_gltf["meshes"] || [])
      primitive = List.first(first_mesh["primitives"] || [])
      ext_bmesh = get_in(primitive, ["extensions", "EXT_mesh_bmesh"])

      assert ext_bmesh != nil
      assert Map.has_key?(ext_bmesh, "vertices")
      assert Map.has_key?(ext_bmesh, "edges")
      assert Map.has_key?(ext_bmesh, "faces")
      assert Map.has_key?(ext_bmesh, "loops")

      # Verify EXT_mesh_bmesh extension structure
      vertices = ext_bmesh["vertices"]
      assert Map.has_key?(vertices, "count")
      assert Map.has_key?(vertices, "positions")
      # In mock mode, positions is a list; in real mode it would be an accessor index
      assert is_list(vertices["positions"]) or is_integer(vertices["positions"])

      edges = ext_bmesh["edges"]
      assert Map.has_key?(edges, "count")
      assert Map.has_key?(edges, "vertices")
      # In mock mode, vertices is a list; in real mode it would be an accessor index
      assert is_list(edges["vertices"]) or is_integer(edges["vertices"])

      faces = ext_bmesh["faces"]
      assert Map.has_key?(faces, "count")
      assert Map.has_key?(faces, "vertices")
      assert Map.has_key?(faces, "offsets")
      # In mock mode, vertices is a list; in real mode it would be an accessor index
      assert is_list(faces["vertices"]) or is_integer(faces["vertices"])
      assert is_integer(faces["offsets"])   # Should be accessor index

      # Test reconstruction functions work with accessor-based data
      accessors = exported_gltf["accessors"] || []
      bufferViews = exported_gltf["bufferViews"] || []
      buffers = exported_gltf["buffers"] || []

      # Reconstruct actual data using accessor indices
      reconstructed_vertices = BpyMcp.BpyMesh.test_reconstruct_vertices_from_accessors(ext_bmesh, accessors, bufferViews, buffers)
      reconstructed_edges = BpyMcp.BpyMesh.test_reconstruct_edges_from_accessors(ext_bmesh, accessors, bufferViews, buffers)
      reconstructed_faces = BpyMcp.BpyMesh.test_reconstruct_faces_from_accessors(ext_bmesh, accessors, bufferViews, buffers)

      # Verify reconstructed data
      assert length(reconstructed_vertices) == vertices["count"]
      assert length(reconstructed_edges) == edges["count"]
      assert length(reconstructed_faces) == faces["count"]

      # Each vertex should be [x, y, z]
      assert Enum.all?(reconstructed_vertices, fn v -> length(v) == 3 end)

      # Each edge should be [v1, v2]
      assert Enum.all?(reconstructed_edges, fn e -> length(e) == 2 end)

      # Each face should be a list of vertex indices
      assert Enum.all?(reconstructed_faces, fn f -> is_list(f) and length(f) > 0 end)
    end
  end

  # Helper function to extract mesh count from import message
  defp extract_mesh_count(message) do
    case Regex.run(~r/Imported (\d+) meshes/, message) do
      [_, count_str] -> String.to_integer(count_str)
      _ -> 0
    end
  end
end
