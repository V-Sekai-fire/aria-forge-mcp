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
end
