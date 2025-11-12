# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Planning.Execution do
  @moduledoc """
  Plan execution functionality with batch mode support.
  """

  alias AriaForge.Tools.{Objects, Materials, Scene, Introspection, Animation, MCPBlenderHelper}
  alias AriaForge.Tools.Planning.Utils

  @doc """
  Executes plan steps sequentially.
  """
  @spec execute_plan_steps(map(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def execute_plan_steps(plan, temp_dir) do
    execute_plan_steps(plan, temp_dir, batch: false)
  end

  @doc """
  Executes plan steps with optional batch mode.
  
  When batch mode is enabled, independent steps are grouped and executed
  together in a single MCP Blender call for better performance.
  """
  @spec execute_plan_steps(map(), String.t(), keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def execute_plan_steps(plan, temp_dir, opts \\ []) do
    steps = Map.get(plan, "steps", [])
    batch_mode = Keyword.get(opts, :batch, false)

    if batch_mode do
      execute_plan_batched(steps, temp_dir)
    else
      execute_plan_sequential(steps, temp_dir)
    end
  end

  defp execute_plan_sequential(steps, temp_dir) do
    results =
      steps
      |> Enum.reduce_while({[], []}, fn step, {successes, failures} ->
        tool = Map.get(step, "tool")
        args = Map.get(step, "args", %{})

        result = execute_step(tool, args, temp_dir)

        case result do
          {:ok, _} ->
            {:cont, {[step | successes], failures}}

          {:error, reason} ->
            {:halt, {successes, [{step, reason} | failures]}}
        end
      end)

    case results do
      {success_steps, []} ->
        {:ok, "Plan executed successfully: #{length(success_steps)} steps completed"}

      {success_steps, failures} ->
        failure_count = length(failures)
        {:error, "Plan execution failed: #{failure_count} steps failed out of #{length(success_steps) + failure_count}"}
    end
  end

  defp execute_plan_batched(steps, temp_dir) do
    # Group steps into batches based on dependencies and tool type
    batches = group_steps_into_batches(steps)

    results =
      batches
      |> Enum.reduce_while({[], []}, fn batch, {all_successes, all_failures} ->
        result = execute_batch(batch, temp_dir)

        case result do
          {:ok, batch_successes} ->
            {:cont, {batch_successes ++ all_successes, all_failures}}

          {:error, batch_failures} ->
            # Continue with other batches even if one fails
            {:cont, {all_successes, batch_failures ++ all_failures}}
        end
      end)

    case results do
      {success_steps, []} ->
        {:ok, "Plan executed successfully in batch mode: #{length(success_steps)} steps completed"}

      {success_steps, failures} ->
        failure_count = length(failures)
        {:error, "Plan execution failed: #{failure_count} steps failed out of #{length(success_steps) + failure_count}"}
    end
  end

  defp group_steps_into_batches(steps) do
    # Simple batching: group steps by tool type that can be batched
    # For now, we'll batch create_cube and create_sphere operations together
    # More sophisticated dependency analysis can be added later
    
    steps
    |> Enum.with_index()
    |> Enum.group_by(fn {step, _idx} ->
      tool = Map.get(step, "tool")
      # Determine if this step can be batched
      batchable?(tool)
    end)
    |> then(fn grouped ->
      # Separate batchable and non-batchable steps
      batchable = Map.get(grouped, true, []) |> Enum.map(fn {step, idx} -> {step, idx} end)
      non_batchable = Map.get(grouped, false, []) |> Enum.map(fn {step, idx} -> {step, idx} end)
      
      # Group batchable steps by tool type
      batchable_batches = 
        batchable
        |> Enum.group_by(fn {step, _idx} -> Map.get(step, "tool") end)
        |> Map.values()
      
      # Each non-batchable step is its own batch
      non_batchable_batches = Enum.map(non_batchable, fn {step, idx} -> [{step, idx}] end)
      
      batchable_batches ++ non_batchable_batches
    end)
  end

  defp batchable?(tool) do
    # Tools that can be batched together in a single MCP Blender call
    tool in ["create_cube", "create_sphere"]
  end

  defp execute_batch(batch, temp_dir) do
    # Extract steps and their indices
    {steps, _indices} = Enum.unzip(batch)
    
    # Check if all steps use the same tool
    tools = Enum.map(steps, &Map.get(&1, "tool")) |> Enum.uniq()
    
    case tools do
      [tool] when tool in ["create_cube", "create_sphere"] ->
        # Batch execute multiple objects of the same type
        execute_object_batch(tool, steps, temp_dir)
      
      _ ->
        # Mixed tools or non-batchable - execute sequentially
        execute_batch_sequential(steps, temp_dir)
    end
  end

  defp execute_object_batch(tool, steps, _temp_dir) do
    # Build a single Python script that creates all objects in one call
    code = build_batch_object_code(tool, steps)
    
    case MCPBlenderHelper.execute_blender_code(code) do
      {:ok, _result} ->
        # All objects created successfully
        {:ok, steps}
      
      {:error, reason} ->
        # Batch failed - return all steps as failures
        failures = Enum.map(steps, fn step -> {step, reason} end)
        {:error, failures}
    end
  end

  defp build_batch_object_code(tool, steps) do
    import_code = """
import bpy
import bmesh
import math
"""
    
    object_creations = 
      steps
      |> Enum.map(fn step ->
        args = Map.get(step, "args", %{})
        name = Map.get(args, "name", "Object")
        location = Map.get(args, "location", [0, 0, 0])
        [x, y, z] = location
        
        case tool do
          "create_cube" ->
            size = Map.get(args, "size", 2.0)
            half_size = size / 2.0
            build_cube_code(name, x, y, z, half_size)
          
          "create_sphere" ->
            radius = Map.get(args, "radius", 1.0)
            height = radius * 2.0
            radius_bottom = radius
            radius_top = radius
            build_tapered_capsule_code(name, x, y, z, height, radius_bottom, radius_top)
        end
      end)
      |> Enum.join("\n\n")
    
    import_code <> "\n\n" <> object_creations <> "\n\nresult = f\"Batch created #{length(steps)} objects\"\nresult"
  end

  defp build_cube_code(name, x, y, z, half_size) do
    """
# Create cube: #{name}
mesh_#{sanitize_name(name)} = bpy.data.meshes.new(name='#{name}')
obj_#{sanitize_name(name)} = bpy.data.objects.new('#{name}', mesh_#{sanitize_name(name)})
bpy.context.collection.objects.link(obj_#{sanitize_name(name)})

bm_#{sanitize_name(name)} = bmesh.new()
# Create 8 vertices
v1_#{sanitize_name(name)} = bm_#{sanitize_name(name)}.verts.new((-#{half_size}, -#{half_size}, -#{half_size}))
v2_#{sanitize_name(name)} = bm_#{sanitize_name(name)}.verts.new((#{half_size}, -#{half_size}, -#{half_size}))
v3_#{sanitize_name(name)} = bm_#{sanitize_name(name)}.verts.new((#{half_size}, #{half_size}, -#{half_size}))
v4_#{sanitize_name(name)} = bm_#{sanitize_name(name)}.verts.new((-#{half_size}, #{half_size}, -#{half_size}))
v5_#{sanitize_name(name)} = bm_#{sanitize_name(name)}.verts.new((-#{half_size}, -#{half_size}, #{half_size}))
v6_#{sanitize_name(name)} = bm_#{sanitize_name(name)}.verts.new((#{half_size}, -#{half_size}, #{half_size}))
v7_#{sanitize_name(name)} = bm_#{sanitize_name(name)}.verts.new((#{half_size}, #{half_size}, #{half_size}))
v8_#{sanitize_name(name)} = bm_#{sanitize_name(name)}.verts.new((-#{half_size}, #{half_size}, #{half_size}))

bm_#{sanitize_name(name)}.verts.ensure_lookup_table()

# Create 6 faces
bm_#{sanitize_name(name)}.faces.new([v1_#{sanitize_name(name)}, v2_#{sanitize_name(name)}, v3_#{sanitize_name(name)}, v4_#{sanitize_name(name)}])
bm_#{sanitize_name(name)}.faces.new([v8_#{sanitize_name(name)}, v7_#{sanitize_name(name)}, v6_#{sanitize_name(name)}, v5_#{sanitize_name(name)}])
bm_#{sanitize_name(name)}.faces.new([v2_#{sanitize_name(name)}, v6_#{sanitize_name(name)}, v7_#{sanitize_name(name)}, v3_#{sanitize_name(name)}])
bm_#{sanitize_name(name)}.faces.new([v4_#{sanitize_name(name)}, v8_#{sanitize_name(name)}, v5_#{sanitize_name(name)}, v1_#{sanitize_name(name)}])
bm_#{sanitize_name(name)}.faces.new([v3_#{sanitize_name(name)}, v7_#{sanitize_name(name)}, v8_#{sanitize_name(name)}, v4_#{sanitize_name(name)}])
bm_#{sanitize_name(name)}.faces.new([v1_#{sanitize_name(name)}, v5_#{sanitize_name(name)}, v6_#{sanitize_name(name)}, v2_#{sanitize_name(name)}])

bmesh.ops.translate(bm_#{sanitize_name(name)}, vec=(#{x}, #{y}, #{z}), verts=bm_#{sanitize_name(name)}.verts[:])
bm_#{sanitize_name(name)}.to_mesh(mesh_#{sanitize_name(name)})
bm_#{sanitize_name(name)}.free()
mesh_#{sanitize_name(name)}.update()
"""
  end

  defp build_tapered_capsule_code(name, x, y, z, height, radius_bottom, radius_top) do
    u_segments = 32
    v_hemisphere_segments = 8
    v_cylinder_segments = 4
    half_height = height / 2.0
    
    # Generate full tapered capsule code (same as in Objects.create_sphere)
    """
# Create tapered capsule: #{name}
mesh_#{sanitize_name(name)} = bpy.data.meshes.new(name='#{name}')
obj_#{sanitize_name(name)} = bpy.data.objects.new('#{name}', mesh_#{sanitize_name(name)})
bpy.context.collection.objects.link(obj_#{sanitize_name(name)})

bm_#{sanitize_name(name)} = bmesh.new()

height_#{sanitize_name(name)} = #{height}
radius_bottom_#{sanitize_name(name)} = #{radius_bottom}
radius_top_#{sanitize_name(name)} = #{radius_top}
u_segments_#{sanitize_name(name)} = #{u_segments}
v_hemisphere_segments_#{sanitize_name(name)} = #{v_hemisphere_segments}
v_cylinder_segments_#{sanitize_name(name)} = #{v_cylinder_segments}

half_height_#{sanitize_name(name)} = height_#{sanitize_name(name)} / 2.0
verts_#{sanitize_name(name)} = []

# Create bottom hemisphere
for i in range(v_hemisphere_segments_#{sanitize_name(name)}):
    v_angle = math.pi * (i + 1) / (2 * v_hemisphere_segments_#{sanitize_name(name)})
    y_offset = -math.cos(v_angle) * radius_bottom_#{sanitize_name(name)}
    ring_radius = math.sin(v_angle) * radius_bottom_#{sanitize_name(name)}
    y_pos = -half_height_#{sanitize_name(name)} + y_offset
    
    for j in range(u_segments_#{sanitize_name(name)}):
        u_angle = 2 * math.pi * j / u_segments_#{sanitize_name(name)}
        x_pos = ring_radius * math.cos(u_angle)
        z_pos = ring_radius * math.sin(u_angle)
        vert = bm_#{sanitize_name(name)}.verts.new((x_pos, y_pos, z_pos))
        verts_#{sanitize_name(name)}.append(vert)

# Create cylindrical middle section
cylinder_start_idx_#{sanitize_name(name)} = v_hemisphere_segments_#{sanitize_name(name)} * u_segments_#{sanitize_name(name)}
for i in range(v_cylinder_segments_#{sanitize_name(name)}):
    t = (i + 1) / (v_cylinder_segments_#{sanitize_name(name)} + 1)
    current_radius = radius_bottom_#{sanitize_name(name)} + (radius_top_#{sanitize_name(name)} - radius_bottom_#{sanitize_name(name)}) * t
    y_pos = -half_height_#{sanitize_name(name)} + height_#{sanitize_name(name)} * t
    
    for j in range(u_segments_#{sanitize_name(name)}):
        u_angle = 2 * math.pi * j / u_segments_#{sanitize_name(name)}
        x_pos = current_radius * math.cos(u_angle)
        z_pos = current_radius * math.sin(u_angle)
        vert = bm_#{sanitize_name(name)}.verts.new((x_pos, y_pos, z_pos))
        verts_#{sanitize_name(name)}.append(vert)

# Create top hemisphere
for i in range(v_hemisphere_segments_#{sanitize_name(name)}):
    v_angle = math.pi * (v_hemisphere_segments_#{sanitize_name(name)} - i) / (2 * v_hemisphere_segments_#{sanitize_name(name)})
    y_offset = -math.cos(v_angle) * radius_top_#{sanitize_name(name)}
    ring_radius = math.sin(v_angle) * radius_top_#{sanitize_name(name)}
    y_pos = half_height_#{sanitize_name(name)} + y_offset
    
    for j in range(u_segments_#{sanitize_name(name)}):
        u_angle = 2 * math.pi * j / u_segments_#{sanitize_name(name)}
        x_pos = ring_radius * math.cos(u_angle)
        z_pos = ring_radius * math.sin(u_angle)
        vert = bm_#{sanitize_name(name)}.verts.new((x_pos, y_pos, z_pos))
        verts_#{sanitize_name(name)}.append(vert)

# Add poles
bottom_pole_#{sanitize_name(name)} = bm_#{sanitize_name(name)}.verts.new((0, -half_height_#{sanitize_name(name)} - radius_bottom_#{sanitize_name(name)}, 0))
verts_#{sanitize_name(name)}.append(bottom_pole_#{sanitize_name(name)})
top_pole_#{sanitize_name(name)} = bm_#{sanitize_name(name)}.verts.new((0, half_height_#{sanitize_name(name)} + radius_top_#{sanitize_name(name)}, 0))
verts_#{sanitize_name(name)}.append(top_pole_#{sanitize_name(name)})

bm_#{sanitize_name(name)}.verts.ensure_lookup_table()

# Create faces for bottom hemisphere
for j in range(u_segments_#{sanitize_name(name)}):
    v1_idx = j
    v2_idx = (j + 1) % u_segments_#{sanitize_name(name)}
    v1 = verts_#{sanitize_name(name)}[v1_idx]
    v2 = verts_#{sanitize_name(name)}[v2_idx]
    bm_#{sanitize_name(name)}.faces.new([bottom_pole_#{sanitize_name(name)}, v2, v1])

for i in range(v_hemisphere_segments_#{sanitize_name(name)} - 1):
    for j in range(u_segments_#{sanitize_name(name)}):
        v1_idx = i * u_segments_#{sanitize_name(name)} + j
        v2_idx = i * u_segments_#{sanitize_name(name)} + (j + 1) % u_segments_#{sanitize_name(name)}
        v3_idx = (i + 1) * u_segments_#{sanitize_name(name)} + (j + 1) % u_segments_#{sanitize_name(name)}
        v4_idx = (i + 1) * u_segments_#{sanitize_name(name)} + j
        
        v1 = verts_#{sanitize_name(name)}[v1_idx]
        v2 = verts_#{sanitize_name(name)}[v2_idx]
        v3 = verts_#{sanitize_name(name)}[v3_idx]
        v4 = verts_#{sanitize_name(name)}[v4_idx]
        
        bm_#{sanitize_name(name)}.faces.new([v1, v2, v3, v4])

# Create faces for cylindrical middle section
for i in range(v_cylinder_segments_#{sanitize_name(name)}):
    for j in range(u_segments_#{sanitize_name(name)}):
        v1_idx = cylinder_start_idx_#{sanitize_name(name)} + i * u_segments_#{sanitize_name(name)} + j
        v2_idx = cylinder_start_idx_#{sanitize_name(name)} + i * u_segments_#{sanitize_name(name)} + (j + 1) % u_segments_#{sanitize_name(name)}
        v3_idx = cylinder_start_idx_#{sanitize_name(name)} + (i + 1) * u_segments_#{sanitize_name(name)} + (j + 1) % u_segments_#{sanitize_name(name)}
        v4_idx = cylinder_start_idx_#{sanitize_name(name)} + (i + 1) * u_segments_#{sanitize_name(name)} + j
        
        v1 = verts_#{sanitize_name(name)}[v1_idx]
        v2 = verts_#{sanitize_name(name)}[v2_idx]
        v3 = verts_#{sanitize_name(name)}[v3_idx]
        v4 = verts_#{sanitize_name(name)}[v4_idx]
        
        bm_#{sanitize_name(name)}.faces.new([v1, v2, v3, v4])

# Create faces for top hemisphere
top_hemisphere_start_idx_#{sanitize_name(name)} = (v_hemisphere_segments_#{sanitize_name(name)} + v_cylinder_segments_#{sanitize_name(name)}) * u_segments_#{sanitize_name(name)}
for i in range(v_hemisphere_segments_#{sanitize_name(name)} - 1):
    for j in range(u_segments_#{sanitize_name(name)}):
        v1_idx = top_hemisphere_start_idx_#{sanitize_name(name)} + i * u_segments_#{sanitize_name(name)} + j
        v2_idx = top_hemisphere_start_idx_#{sanitize_name(name)} + i * u_segments_#{sanitize_name(name)} + (j + 1) % u_segments_#{sanitize_name(name)}
        v3_idx = top_hemisphere_start_idx_#{sanitize_name(name)} + (i + 1) * u_segments_#{sanitize_name(name)} + (j + 1) % u_segments_#{sanitize_name(name)}
        v4_idx = top_hemisphere_start_idx_#{sanitize_name(name)} + (i + 1) * u_segments_#{sanitize_name(name)} + j
        
        v1 = verts_#{sanitize_name(name)}[v1_idx]
        v2 = verts_#{sanitize_name(name)}[v2_idx]
        v3 = verts_#{sanitize_name(name)}[v3_idx]
        v4 = verts_#{sanitize_name(name)}[v4_idx]
        
        bm_#{sanitize_name(name)}.faces.new([v1, v2, v3, v4])

# Top pole connects to last ring
last_ring_start_#{sanitize_name(name)} = top_hemisphere_start_idx_#{sanitize_name(name)} + (v_hemisphere_segments_#{sanitize_name(name)} - 1) * u_segments_#{sanitize_name(name)}
for j in range(u_segments_#{sanitize_name(name)}):
    v1_idx = last_ring_start_#{sanitize_name(name)} + j
    v2_idx = last_ring_start_#{sanitize_name(name)} + (j + 1) % u_segments_#{sanitize_name(name)}
    v1 = verts_#{sanitize_name(name)}[v1_idx]
    v2 = verts_#{sanitize_name(name)}[v2_idx]
    bm_#{sanitize_name(name)}.faces.new([v1, v2, top_pole_#{sanitize_name(name)}])

# Transform to location
bmesh.ops.translate(bm_#{sanitize_name(name)}, vec=(#{x}, #{y}, #{z}), verts=bm_#{sanitize_name(name)}.verts[:])
bm_#{sanitize_name(name)}.to_mesh(mesh_#{sanitize_name(name)})
bm_#{sanitize_name(name)}.free()
mesh_#{sanitize_name(name)}.update()
"""
  end

  defp sanitize_name(name) do
    # Sanitize name for use in Python variable names
    String.replace(name, ~r/[^a-zA-Z0-9_]/, "_")
  end

  defp execute_batch_sequential(steps, temp_dir) do
    # For non-batchable or mixed batches, execute sequentially
    results =
      steps
      |> Enum.reduce({[], []}, fn step, {successes, failures} ->
        tool = Map.get(step, "tool")
        args = Map.get(step, "args", %{})
        
        result = execute_step(tool, args, temp_dir)
        
        case result do
          {:ok, _} -> {[step | successes], failures}
          {:error, reason} -> {successes, [{step, reason} | failures]}
        end
      end)
    
    case results do
      {successes, []} -> {:ok, successes}
      {successes, failures} -> {:error, failures}
    end
  end

  @doc """
  Executes a single plan step and records its duration.
  """
  @spec execute_step(String.t(), map(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def execute_step(tool, args, temp_dir) do
    # Record start time
    start_time = System.monotonic_time(:millisecond)
    
    result = case tool do
      "create_cube" ->
        name = Map.get(args, "name", "Cube")
        location = Map.get(args, "location", [0, 0, 0])
        size = Map.get(args, "size", 2.0)
        Objects.create_cube(name, location, size, temp_dir)

      "create_sphere" ->
        name = Map.get(args, "name", "Sphere")
        location = Map.get(args, "location", [0, 0, 0])
        radius = Map.get(args, "radius", 1.0)
        Objects.create_sphere(name, location, radius, temp_dir)

      "set_material" -> 
        object_name = Map.get(args, "object_name")
        material_name = Map.get(args, "material_name", "Material")
        color = Map.get(args, "color", [0.8, 0.8, 0.8, 1.0])
        Materials.set_material(object_name, material_name, color, temp_dir)

      "introspect_blender" ->
        object_path = Map.get(args, "object_path", "bmesh")
        Introspection.introspect_blender(object_path, temp_dir)

      "introspect_python" ->
        object_path = Map.get(args, "object_path", "json")
        prep_code = Map.get(args, "prep_code", nil)
        Introspection.introspect_python(object_path, prep_code, temp_dir)

      "reset_scene" ->
        Scene.reset_scene(temp_dir)

      "set_scene_fps" ->
        fps = Map.get(args, "fps", 30)
        Scene.set_scene_fps(fps, temp_dir)

      "get_scene_info" ->
        Scene.get_scene_info(temp_dir)

      "set_keyframe" ->
        object_name = Map.get(args, "object")
        property = Map.get(args, "property", "location")
        value = Map.get(args, "value")
        frame = Map.get(args, "frame", 1)
        Animation.set_keyframe(object_name, property, value, frame, temp_dir)

      _ ->
        {:error, "Unknown tool: #{tool}"}
    end
    
    # Record end time and calculate duration
    end_time = System.monotonic_time(:millisecond)
    duration_ms = end_time - start_time
    duration_seconds = duration_ms / 1000.0
    duration_iso = Utils.seconds_to_iso_duration(duration_seconds)
    
    # Return result with duration information
    case result do
      {:ok, message} ->
        {:ok, "#{message} (duration: #{duration_iso})"}
      error ->
        error
    end
  end
end

