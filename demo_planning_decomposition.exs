# Demo: Show how method decomposition handles dependencies
# This shows the domain structure without needing aria_planner

IO.puts("=== Planning Domain: Method Decomposition Handles Dependencies ===\n")

# Simulate the domain methods
stacking_animation_method = fn _state, goal ->
  count = Map.get(goal, "count", 3)
  base_location = Map.get(goal, "base_location", [0, 0, 0])
  spacing = Map.get(goal, "spacing", 2.0)
  start_frame = Map.get(goal, "start_frame", 1)
  frames_per_object = Map.get(goal, "frames_per_object", 30)
  
  Enum.map(0..(count - 1), fn i ->
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
    
    {"animate_object", %{
      "object_name" => obj_name,
      "object_type" => "cube",
      "start_location" => start_location,
      "keyframes" => [
        %{"frame" => frame_start, "property" => "location", "value" => final_location},
        %{"frame" => frame_end, "property" => "location", "value" => final_location}
      ]
    }}
  end)
end

animate_object_method = fn _state, goal ->
  object_name = Map.get(goal, "object_name")
  object_type = Map.get(goal, "object_type", "cube")
  start_location = Map.get(goal, "start_location", [0, 0, 0])
  keyframes = Map.get(goal, "keyframes", [])
  
  tasks = case object_type do
    "cube" ->
      [{"create_cube", %{
        "name" => object_name,
        "location" => start_location,
        "size" => 1.5
      }}]
    "sphere" ->
      [{"create_sphere", %{
        "name" => object_name,
        "location" => start_location,
        "radius" => 1.0
      }}]
    _ ->
      [{"create_cube", %{
        "name" => object_name,
        "location" => start_location,
        "size" => 1.5
      }}]
  end
  
  keyframe_tasks = Enum.map(keyframes, fn kf ->
    {"set_keyframe", %{
      "object" => object_name,
      "property" => Map.get(kf, "property", "location"),
      "value" => Map.get(kf, "value"),
      "frame" => Map.get(kf, "frame", 1)
    }}
  end)
  
  tasks ++ keyframe_tasks
end

prepare_scene_method = fn _state, goal ->
  tasks = []
  
  tasks = if Map.get(goal, "introspect_before", false) do
    tasks ++ [{"introspect_scene", %{}}]
  else
    tasks
  end
  
  tasks = tasks ++ [{"reset_scene", %{}}]
  
  fps = Map.get(goal, "fps", 30)
  tasks = tasks ++ [{"set_scene_fps", %{"fps" => fps}}]
  
  tasks = if Map.get(goal, "introspect_after", false) do
    tasks ++ [{"introspect_scene", %{}}]
  else
    tasks
  end
  
  tasks
end

IO.puts("1. prepare_scene decomposition:")
prepare_tasks = prepare_scene_method.(%{}, %{"fps" => 30})
Enum.each(Enum.with_index(prepare_tasks, 1), fn {{task, args}, idx} ->
  IO.puts("   #{idx}. #{task} #{inspect(args)}")
end)

IO.puts("\n2. stacking_animation decomposition:")
stacking_tasks = stacking_animation_method.(%{}, %{
  "count" => 3,
  "base_location" => [0, 0, 0],
  "spacing" => 2.0,
  "start_frame" => 1,
  "frames_per_object" => 30
})
IO.puts("   Decomposes to #{length(stacking_tasks)} animate_object tasks:")
Enum.each(stacking_tasks, fn {task, args} ->
  obj_name = Map.get(args, "object_name")
  IO.puts("     - #{task} for #{obj_name}")
end)

IO.puts("\n3. animate_object decomposition (for StackCube1):")
{_task_name, animate_args} = Enum.at(stacking_tasks, 0)
animate_tasks = animate_object_method.(%{}, animate_args)
IO.puts("   Decomposes to:")
Enum.each(Enum.with_index(animate_tasks, 1), fn {{task, args}, idx} ->
  IO.puts("     #{idx}. #{task}")
  case task do
    "create_cube" ->
      IO.puts("        Name: #{Map.get(args, "name")}")
      IO.puts("        Location: #{inspect(Map.get(args, "location"))}")
    "set_keyframe" ->
      IO.puts("        Object: #{Map.get(args, "object")}")
      IO.puts("        Frame: #{Map.get(args, "frame")}")
      IO.puts("        Value: #{inspect(Map.get(args, "value"))}")
  end
end)

IO.puts("\n=== How Dependencies Work ===\n")
IO.puts("✓ Commands are pure state transformers (no preconditions)")
IO.puts("✓ Methods handle dependencies via decomposition:")
IO.puts("  - stacking_animation -> animate_object (for each object)")
IO.puts("  - animate_object -> create_cube, then set_keyframe")
IO.puts("✓ Method decomposition ensures create_cube comes before set_keyframe")
IO.puts("✓ No explicit dependency constraints needed!")
IO.puts("✓ Planner uses backtracking to order operations correctly")

IO.puts("\n=== Expected Plan (via Method Decomposition) ===\n")
IO.puts("1. reset_scene")
IO.puts("2. set_scene_fps (fps: 30)")
IO.puts("3. create_cube('StackCube1', ...)")
IO.puts("4. set_keyframe('StackCube1', frame: 1, ...)")
IO.puts("5. set_keyframe('StackCube1', frame: 31, ...)")
IO.puts("6. create_cube('StackCube2', ...)")
IO.puts("7. set_keyframe('StackCube2', frame: 31, ...)")
IO.puts("8. set_keyframe('StackCube2', frame: 61, ...)")
IO.puts("9. create_cube('StackCube3', ...)")
IO.puts("10. set_keyframe('StackCube3', frame: 61, ...)")
IO.puts("11. set_keyframe('StackCube3', frame: 91, ...)")
IO.puts("\n✓ Dependencies handled automatically via method decomposition!")

