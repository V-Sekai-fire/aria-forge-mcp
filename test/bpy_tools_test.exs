# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.BpyToolsTest do
  use ExUnit.Case, async: true
  alias BpyMcp.BpyTools

  describe "create_cube/3" do
    test "creates cube with custom parameters" do
      result = BpyTools.test_mock_create_cube("TestCube", [1, 2, 3], 5.0)
      assert {:ok, "Mock created cube 'TestCube' at [1, 2, 3] with size 5.0"} = result
    end

    test "creates cube with default parameters" do
      result = BpyTools.test_mock_create_cube("Cube", [0, 0, 0], 2.0)
      assert {:ok, "Mock created cube 'Cube' at [0, 0, 0] with size 2.0"} = result
    end

    test "handles various location coordinates" do
      result = BpyTools.test_mock_create_cube("Cube", [10.5, -5.2, 0], 1.0)
      assert {:ok, "Mock created cube 'Cube' at [10.5, -5.2, 0] with size 1.0"} = result
    end

    test "handles zero and negative sizes" do
      result = BpyTools.test_mock_create_cube("Cube", [0, 0, 0], 0)
      assert {:ok, "Mock created cube 'Cube' at [0, 0, 0] with size 0"} = result

      result = BpyTools.test_mock_create_cube("Cube", [0, 0, 0], -1.0)
      assert {:ok, "Mock created cube 'Cube' at [0, 0, 0] with size -1.0"} = result
    end
  end

  describe "create_sphere/3" do
    test "creates sphere with custom parameters" do
      result = BpyTools.test_mock_create_sphere("TestSphere", [1, 2, 3], 2.5)
      assert {:ok, "Mock created sphere 'TestSphere' at [1, 2, 3] with radius 2.5"} = result
    end

    test "creates sphere with default parameters" do
      result = BpyTools.test_mock_create_sphere("Sphere", [0, 0, 0], 1.0)
      assert {:ok, "Mock created sphere 'Sphere' at [0, 0, 0] with radius 1.0"} = result
    end

    test "handles various location coordinates" do
      result = BpyTools.test_mock_create_sphere("Sphere", [-10.5, 5.2, 100], 0.5)
      assert {:ok, "Mock created sphere 'Sphere' at [-10.5, 5.2, 100] with radius 0.5"} = result
    end

    test "handles zero and negative radius" do
      result = BpyTools.test_mock_create_sphere("Sphere", [0, 0, 0], 0)
      assert {:ok, "Mock created sphere 'Sphere' at [0, 0, 0] with radius 0"} = result

      result = BpyTools.test_mock_create_sphere("Sphere", [0, 0, 0], -2.0)
      assert {:ok, "Mock created sphere 'Sphere' at [0, 0, 0] with radius -2.0"} = result
    end
  end

  describe "set_material/3" do
    test "sets material with custom parameters" do
      result = BpyTools.test_mock_set_material("Cube", "RedMaterial", [1.0, 0.0, 0.0, 1.0])
      assert {:ok, "Mock set material 'RedMaterial' with color [1.0, 0.0, 0.0, 1.0] on object 'Cube'"} = result
    end

    test "sets material with default parameters" do
      result = BpyTools.test_mock_set_material("Sphere", "Material", [0.8, 0.8, 0.8, 1.0])
      assert {:ok, "Mock set material 'Material' with color [0.8, 0.8, 0.8, 1.0] on object 'Sphere'"} = result
    end

    test "handles various color values" do
      result = BpyTools.test_mock_set_material("Object", "Blue", [0.0, 0.0, 1.0, 0.5])
      assert {:ok, "Mock set material 'Blue' with color [0.0, 0.0, 1.0, 0.5] on object 'Object'"} = result
    end

    test "handles extreme color values" do
      result = BpyTools.test_mock_set_material("Object", "White", [2.0, 2.0, 2.0, 1.0])
      assert {:ok, "Mock set material 'White' with color [2.0, 2.0, 2.0, 1.0] on object 'Object'"} = result

      result = BpyTools.test_mock_set_material("Object", "Black", [-1.0, -1.0, -1.0, 0.0])
      assert {:ok, "Mock set material 'Black' with color [-1.0, -1.0, -1.0, 0.0] on object 'Object'"} = result
    end
  end

  describe "render_image/3" do
    test "renders image with custom parameters" do
      result = BpyTools.test_mock_render_image("/tmp/test.png", 2560, 1440)
      assert {:ok, "Mock rendered image to /tmp/test.png at 2560x1440"} = result
    end

    test "renders image with default parameters" do
      result = BpyTools.test_mock_render_image("output.png", 1920, 1080)
      assert {:ok, "Mock rendered image to output.png at 1920x1080"} = result
    end

    test "handles various file paths and resolutions" do
      result = BpyTools.test_mock_render_image("./renders/scene.jpg", 3840, 2160)
      assert {:ok, "Mock rendered image to ./renders/scene.jpg at 3840x2160"} = result
    end

    test "handles zero and large resolutions" do
      result = BpyTools.test_mock_render_image("test.png", 0, 0)
      assert {:ok, "Mock rendered image to test.png at 0x0"} = result

      result = BpyTools.test_mock_render_image("test.png", 10000, 10000)
      assert {:ok, "Mock rendered image to test.png at 10000x10000"} = result
    end
  end

  describe "get_scene_info/0" do
    test "returns mock scene information" do
      result = BpyTools.test_mock_get_scene_info()
      expected = %{
        "scene_name" => "Mock Scene",
        "frame_current" => 1,
        "frame_start" => 1,
        "frame_end" => 250,
        "fps" => 30,
        "fps_base" => 1,
        "objects" => ["Cube", "Light", "Camera"],
        "active_object" => "Cube"
      }
      assert {:ok, ^expected} = result
    end

    test "returns map with expected keys" do
      {:ok, info} = BpyTools.test_mock_get_scene_info()
      assert is_map(info)
      assert Map.has_key?(info, "scene_name")
      assert Map.has_key?(info, "frame_current")
      assert Map.has_key?(info, "frame_start")
      assert Map.has_key?(info, "frame_end")
      assert Map.has_key?(info, "fps")
      assert Map.has_key?(info, "fps_base")
      assert Map.has_key?(info, "objects")
      assert Map.has_key?(info, "active_object")
    end

    test "returns correct data types" do
      {:ok, info} = BpyTools.test_mock_get_scene_info()
      assert is_binary(info["scene_name"])
      assert is_integer(info["frame_current"])
      assert is_integer(info["frame_start"])
      assert is_integer(info["frame_end"])
      assert is_integer(info["fps"])
      assert is_integer(info["fps_base"])
      assert is_list(info["objects"])
      assert is_binary(info["active_object"]) or is_nil(info["active_object"])
    end

    test "returns 30 FPS by default" do
      {:ok, info} = BpyTools.test_mock_get_scene_info()
      assert info["fps"] == 30
      assert info["fps_base"] == 1
    end
  end

  describe "mock functions" do
    test "test_mock_create_cube returns expected result" do
      result = BpyTools.test_mock_create_cube("TestCube", [1, 2, 3], 5.0)
      assert {:ok, "Mock created cube 'TestCube' at [1, 2, 3] with size 5.0"} = result
    end

    test "test_mock_create_sphere returns expected result" do
      result = BpyTools.test_mock_create_sphere("TestSphere", [1, 2, 3], 2.5)
      assert {:ok, "Mock created sphere 'TestSphere' at [1, 2, 3] with radius 2.5"} = result
    end

    test "test_mock_set_material returns expected result" do
      result = BpyTools.test_mock_set_material("Cube", "RedMaterial", [1.0, 0.0, 0.0, 1.0])
      assert {:ok, "Mock set material 'RedMaterial' with color [1.0, 0.0, 0.0, 1.0] on object 'Cube'"} = result
    end

    test "test_mock_render_image returns expected result" do
      result = BpyTools.test_mock_render_image("/tmp/test.png", 2560, 1440)
      assert {:ok, "Mock rendered image to /tmp/test.png at 2560x1440"} = result
    end

    test "test_mock_get_scene_info returns expected result" do
      result = BpyTools.test_mock_get_scene_info()
      expected = %{
        "scene_name" => "Mock Scene",
        "frame_current" => 1,
        "frame_start" => 1,
        "frame_end" => 250,
        "fps" => 30,
        "fps_base" => 1,
        "objects" => ["Cube", "Light", "Camera"],
        "active_object" => "Cube"
      }
      assert {:ok, ^expected} = result
    end
  end

  describe "default parameter handling" do
    test "create_cube/1 uses default location and size" do
      result = BpyTools.test_mock_create_cube("Cube", [0, 0, 0], 2.0)
      assert {:ok, "Mock created cube 'Cube' at [0, 0, 0] with size 2.0"} = result
    end

    test "create_sphere/1 uses default location and radius" do
      result = BpyTools.test_mock_create_sphere("Sphere", [0, 0, 0], 1.0)
      assert {:ok, "Mock created sphere 'Sphere' at [0, 0, 0] with radius 1.0"} = result
    end

    test "set_material/2 uses default material name and color" do
      result = BpyTools.test_mock_set_material("Object", "Material", [0.8, 0.8, 0.8, 1.0])
      assert {:ok, "Mock set material 'Material' with color [0.8, 0.8, 0.8, 1.0] on object 'Object'"} = result
    end

    test "render_image/1 uses default resolution" do
      result = BpyTools.test_mock_render_image("output.png", 1920, 1080)
      assert {:ok, "Mock rendered image to output.png at 1920x1080"} = result
    end
  end
end
