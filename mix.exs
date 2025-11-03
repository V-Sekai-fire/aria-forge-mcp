# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_forge,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      releases: releases(),
      deps: deps(),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      test_coverage: [summary: [threshold: 75], ignore_modules: [AriaForge.NativeService, Mix.Tasks.Mcp.Server]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {AriaForge.Application, []},
      applications: [:logger, :ex_mcp, :pythonx, :briefly, :macfly, :aria_storage, :aria_math, :aria_core, :aria_planner]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_mcp, git: "https://github.com/azmaveth/ex_mcp.git", branch: "master", override: true},
      {:jason, "~> 1.4"},
      {:pythonx, "~> 0.4.0", runtime: false},
      {:briefly, "~> 0.5.1"},
      {:macfly, "~> 0.2.20"},
      {:plug, "~> 1.16"},
      {:plug_cowboy, "~> 2.7"},
      {:aria_storage, git: "https://github.com/V-Sekai-fire/aria-storage.git"},
      {:aria_math, git: "https://github.com/V-Sekai-fire/aria-math.git"},
      {:aria_core, git: "https://github.com/V-Sekai-fire/aria-core.git"},
      {:aria_planner, git: "https://github.com/V-Sekai-fire/aria-planner.git", override: true},
      {:sympy_mcp, git: "https://github.com/V-Sekai-fire/sympy-mcp.git", override: true},
      {:dialyxir, "~> 1.4.6", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  # Release configuration
  defp releases do
    [
      aria_forge: [
        include_executables_for: [:unix],
        applications: [aria_forge: :permanent],
        # Use unique node names to avoid conflicts when multiple instances start
        # Generate node name based on timestamp to ensure uniqueness
        vm_args: "rel/vm.args"
      ]
    ]
  end
end
