# Show a planned plan using the planning system
# This demonstrates the plan structure that would be generated

IO.puts("=== Generating Plan for Stacking Animation ===\n")

# Plan specification
plan_spec = %{
  "initial_state" => %{"objects" => []},
  "tasks" => [
    {"prepare_scene", %{"fps" => 30}},
    {"stacking_animation", %{
      "count" => 3,
      "base_location" => [0, 0, 0],
      "spacing" => 2.0,
      "start_frame" => 1,
      "frames_per_object" => 30
    }}
  ],
  "constraints" => [],
  "domain" => nil,
  "opts" => %{
    "execution" => false,
    "backtracking" => true
  }
}

IO.puts("Plan Specification:")
IO.puts("  Initial State: #{inspect(plan_spec["initial_state"])}")
IO.puts("  Tasks:")
IO.puts("    1. prepare_scene (fps: 30)")
IO.puts("    2. stacking_animation (count: 3, spacing: 2.0)")
IO.puts("  Constraints: [] (dependencies via method decomposition)")
IO.puts("  Backtracking: enabled\n")

# Simulate domain decomposition to show expected plan
IO.puts("=== Domain Decomposition ===\n")

# Simulate prepare_scene decomposition
IO.puts("1. prepare_scene decomposes to:")
IO.puts("   - reset_scene")
IO.puts("   - set_scene_fps (fps: 30)\n")

# Simulate stacking_animation decomposition
IO.puts("2. stacking_animation decomposes to:")
IO.puts("   - animate_object('StackCube1', ...)")
IO.puts("   - animate_object('StackCube2', ...)")
IO.puts("   - animate_object('StackCube3', ...)\n")

# Simulate animate_object decomposition for each
IO.puts("3. animate_object decompositions:\n")

count = 3
base_location = [0, 0, 0]
spacing = 2.0
start_frame = 1
frames_per_object = 30

Enum.each(0..(count - 1), fn i ->
  obj_name = "StackCube#{i + 1}"
  x = Enum.at(base_location, 0) || 0
  y = Enum.at(base_location, 1) || 0
  z = Enum.at(base_location, 2) || 0
  
  start_z = z - (i * spacing) - spacing
  start_location = [x, y, start_z]
  
  final_z = z + (i * spacing)
  final_location = [x, y, final_z]
  
  frame_start = start_frame + (i * frames_per_object)
  frame_end = frame_start + frames_per_object
  
  IO.puts("   #{obj_name}:")
  IO.puts("     - create_cube(name: '#{obj_name}', location: #{inspect(start_location)}, size: 1.5)")
  IO.puts("     - set_keyframe(object: '#{obj_name}', frame: #{frame_start}, value: #{inspect(final_location)})")
  IO.puts("     - set_keyframe(object: '#{obj_name}', frame: #{frame_end}, value: #{inspect(final_location)})")
  IO.puts("")
end)

IO.puts("=== Expected Plan (Ordered by Planner via Backtracking) ===\n")

# Show the final ordered plan
plan_steps = [
  %{
    "tool" => "reset_scene",
    "args" => %{},
    "description" => "Reset scene to clean state",
    "dependencies" => []
  },
  %{
    "tool" => "set_scene_fps",
    "args" => %{"fps" => 30},
    "description" => "Set scene FPS to 30",
    "dependencies" => []
  },
  %{
    "tool" => "create_cube",
    "args" => %{"name" => "StackCube1", "location" => [0, 0, -2.0], "size" => 1.5},
    "description" => "Create cube 'StackCube1'",
    "dependencies" => []
  },
  %{
    "tool" => "set_keyframe",
    "args" => %{"object" => "StackCube1", "property" => "location", "value" => [0, 0, 0.0], "frame" => 1},
    "description" => "Set keyframe for 'StackCube1' at frame 1",
    "dependencies" => ["create_cube:StackCube1"]
  },
  %{
    "tool" => "set_keyframe",
    "args" => %{"object" => "StackCube1", "property" => "location", "value" => [0, 0, 0.0], "frame" => 31},
    "description" => "Set keyframe for 'StackCube1' at frame 31",
    "dependencies" => ["create_cube:StackCube1"]
  },
  %{
    "tool" => "create_cube",
    "args" => %{"name" => "StackCube2", "location" => [0, 0, -4.0], "size" => 1.5},
    "description" => "Create cube 'StackCube2'",
    "dependencies" => []
  },
  %{
    "tool" => "set_keyframe",
    "args" => %{"object" => "StackCube2", "property" => "location", "value" => [0, 0, 2.0], "frame" => 31},
    "description" => "Set keyframe for 'StackCube2' at frame 31",
    "dependencies" => ["create_cube:StackCube2"]
  },
  %{
    "tool" => "set_keyframe",
    "args" => %{"object" => "StackCube2", "property" => "location", "value" => [0, 0, 2.0], "frame" => 61},
    "description" => "Set keyframe for 'StackCube2' at frame 61",
    "dependencies" => ["create_cube:StackCube2"]
  },
  %{
    "tool" => "create_cube",
    "args" => %{"name" => "StackCube3", "location" => [0, 0, -6.0], "size" => 1.5},
    "description" => "Create cube 'StackCube3'",
    "dependencies" => []
  },
  %{
    "tool" => "set_keyframe",
    "args" => %{"object" => "StackCube3", "property" => "location", "value" => [0, 0, 4.0], "frame" => 61},
    "description" => "Set keyframe for 'StackCube3' at frame 61",
    "dependencies" => ["create_cube:StackCube3"]
  },
  %{
    "tool" => "set_keyframe",
    "args" => %{"object" => "StackCube3", "property" => "location", "value" => [0, 0, 4.0], "frame" => 91},
    "description" => "Set keyframe for 'StackCube3' at frame 91",
    "dependencies" => ["create_cube:StackCube3"]
  }
]

IO.puts("Plan JSON Structure:")
IO.puts(String.duplicate("=", 70))

plan_json = %{
  "steps" => plan_steps,
  "total_operations" => length(plan_steps),
  "planner" => "run_lazy",
  "backtracking" => true,
  "dependencies_handled" => "via_method_decomposition"
}

# Pretty print the plan
IO.puts("\nPlan Steps (#{length(plan_steps)} total):\n")

Enum.each(Enum.with_index(plan_steps, 1), fn {step, idx} ->
  tool = Map.get(step, "tool")
  desc = Map.get(step, "description")
  args = Map.get(step, "args")
  deps = Map.get(step, "dependencies", [])
  
  IO.puts("#{idx}. #{tool}")
  IO.puts("   #{desc}")
  
  case tool do
    "create_cube" ->
      IO.puts("   Name: #{Map.get(args, "name")}")
      IO.puts("   Location: #{inspect(Map.get(args, "location"))}")
      IO.puts("   Size: #{Map.get(args, "size")}")
    "set_keyframe" ->
      IO.puts("   Object: #{Map.get(args, "object")}")
      IO.puts("   Frame: #{Map.get(args, "frame")}")
      IO.puts("   Property: #{Map.get(args, "property")}")
      IO.puts("   Value: #{inspect(Map.get(args, "value"))}")
    "set_scene_fps" ->
      IO.puts("   FPS: #{Map.get(args, "fps")}")
    _ ->
      if map_size(args) > 0 do
        IO.puts("   Args: #{inspect(args)}")
      end
  end
  
  if length(deps) > 0 do
    IO.puts("   Dependencies: #{inspect(deps)}")
  end
  
  IO.puts("")
end)

IO.puts(String.duplicate("=", 70))
IO.puts("\nPlan Summary:")
IO.puts("  - Total steps: #{length(plan_steps)}")
IO.puts("  - Object creation: 3 (StackCube1, StackCube2, StackCube3)")
IO.puts("  - Keyframe operations: 6 (2 per object)")
IO.puts("  - Scene setup: 2 (reset_scene, set_scene_fps)")
IO.puts("  - Dependencies: Handled via method decomposition")
IO.puts("  - Backtracking: Ensures create_cube before set_keyframe for each object")
IO.puts("\n✓ Plan structure ready for execution!")

