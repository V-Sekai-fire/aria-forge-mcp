# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.Application do
  @moduledoc false

  use Application

  @doc """
  Configure environment variables for headless Blender operation.
  This prevents GUI initialization and console output that would break MCP stdio protocol.
  """
  @spec configure_headless_blender() :: :ok
  def configure_headless_blender do
    # Set Blender to run in headless/background mode
    System.put_env("BLENDER_HEADLESS", "1")

    # Prevent X11 display issues
    System.put_env("DISPLAY", "")

    # Force Vulkan backend for headless rendering
    System.put_env(
      "VK_ICD_FILENAMES",
      "/usr/share/vulkan/icd.d/intel_icd.x86_64.json:/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"
    )

    System.put_env("VULKAN_SDK", "")
    System.put_env("VK_LAYER_PATH", "")

    # Disable audio and verbose output
    System.put_env("BLENDER_NO_AUDIO", "1")
    System.put_env("BLENDER_VERBOSE", "0")

    # Additional Vulkan-specific settings
    System.put_env("ENABLE_VULKAN_VALIDATION", "0")
    System.put_env("VK_KHRONOS_VALIDATION", "0")

    :ok
  end

  @spec start(:normal | :permanent | :transient, any()) :: {:ok, pid()}
  @impl true
  def start(_type, _args) do
    # Configure Blender for headless operation to prevent GUI initialization
    # and console output that breaks MCP stdio protocol
    configure_headless_blender()

    # Ensure required dependencies are started
    Application.ensure_all_started(:pythonx)
    Application.ensure_all_started(:briefly)

    children = [
      # Registry for scene managers
      {Registry, keys: :unique, name: BpyMcp.SceneRegistry},

      # Dynamic supervisor for scene manager processes
      {DynamicSupervisor, name: BpyMcp.SceneSupervisor, strategy: :one_for_one},

      # Original MCP services
      {BpyMcp.NativeService, [name: BpyMcp.NativeService]}
    ]

    # Start HTTP server instead of stdio server
    children =
      if Mix.env() == :test or System.get_env("MCP_STDIO") == "true" do
        children
      else
        port = System.get_env("PORT", "4000") |> String.to_integer()
        children ++ [
          {Plug.Cowboy, scheme: :http, plug: BpyMcp.HTTPServer, options: [port: port]}
        ]
      end

    opts = [strategy: :one_for_one, name: BpyMcp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
