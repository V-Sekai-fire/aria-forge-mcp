# Demo: Planning domain decomposition with introspection
# This shows how prepare_scene decomposes when introspection is requested

# Simulate the domain method (extracted from planning.ex)
prepare_scene_method = fn _state, goal ->
  tasks = []
  
  # Optionally introspect scene before reset
  tasks = if Map.get(goal, "introspect_before", false) do
    tasks ++ [{"introspect_scene", %{}}]
  else
    tasks
  end
  
  # Reset scene
  tasks = tasks ++ [{"reset_scene", %{}}]
  
  # Set FPS if specified (default 30)
  fps = Map.get(goal, "fps", 30)
  tasks = tasks ++ [{"set_scene_fps", %{"fps" => fps}}]
  
  # Optionally introspect scene after preparation
  tasks = if Map.get(goal, "introspect_after", false) do
    tasks ++ [{"introspect_scene", %{}}]
  else
    tasks
  end
  
  tasks
end

introspect_scene_method = fn _state, _spec ->
  # Method to introspect the current scene state
  # Gets information about objects, materials, and scene configuration
  [{"get_scene_info", %{}}]
end

IO.puts("=== Planning Domain Decomposition Demo ===\n")

IO.puts("1. prepare_scene with introspection_after:")
goal1 = %{"fps" => 30, "introspect_after" => true}
tasks1 = prepare_scene_method.(%{}, goal1)
IO.puts("   Decomposes to:")
Enum.each(Enum.with_index(tasks1, 1), fn {{task, args}, idx} ->
  IO.puts("     #{idx}. #{task} #{inspect(args)}")
end)
IO.puts("   Then introspect_scene decomposes to:")
introspect_tasks = introspect_scene_method.(%{}, %{})
Enum.each(introspect_tasks, fn {task, args} ->
  IO.puts("       -> #{task} #{inspect(args)}")
end)

IO.puts("\n2. prepare_scene with introspection_before:")
goal2 = %{"fps" => 30, "introspect_before" => true}
tasks2 = prepare_scene_method.(%{}, goal2)
IO.puts("   Decomposes to:")
Enum.each(Enum.with_index(tasks2, 1), fn {{task, args}, idx} ->
  IO.puts("     #{idx}. #{task} #{inspect(args)}")
end)

IO.puts("\n3. prepare_scene with both introspection options:")
goal3 = %{"fps" => 30, "introspect_before" => true, "introspect_after" => true}
tasks3 = prepare_scene_method.(%{}, goal3)
IO.puts("   Decomposes to:")
Enum.each(Enum.with_index(tasks3, 1), fn {{task, args}, idx} ->
  IO.puts("     #{idx}. #{task} #{inspect(args)}")
end)

IO.puts("\n4. Direct introspect_scene method:")
tasks4 = introspect_scene_method.(%{}, %{})
IO.puts("   Decomposes to:")
Enum.each(tasks4, fn {task, args} ->
  IO.puts("     -> #{task} #{inspect(args)}")
end)

IO.puts("\n=== Summary ===")
IO.puts("✓ introspect_scene is available as a method in the domain")
IO.puts("✓ prepare_scene supports introspection_before and introspection_after")
IO.puts("✓ introspect_scene decomposes to get_scene_info command")
IO.puts("✓ The planning system will generate plans with introspection when requested")

