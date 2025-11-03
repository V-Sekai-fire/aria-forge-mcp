# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.MixProject do
  use Mix.Project

  def project do
    [
      app: :bpy_mcp,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      releases: releases(),
      deps: deps(),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      test_coverage: [summary: [threshold: 75], ignore_modules: [BpyMcp.NativeService, Mix.Tasks.Mcp.Server]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {BpyMcp.Application, []},
      applications: [:logger, :ex_mcp, :pythonx, :briefly, :macfly]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_mcp, git: "https://github.com/azmaveth/ex_mcp.git", branch: "master"},
      {:jason, "~> 1.4"},
      {:pythonx, "~> 0.4.0", runtime: false},
      {:briefly, "~> 0.5.1"},
      {:macfly, "~> 0.2.20"},
      {:plug, "~> 1.16"},
      {:plug_cowboy, "~> 2.7"},
      {:dialyxir, "~> 1.4.6", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  # Release configuration
  defp releases do
    [
      bpy_mcp: [
        include_executables_for: [:unix],
        applications: [bpy_mcp: :permanent],
        # Use unique node names to avoid conflicts when multiple instances start
        # Generate node name based on timestamp to ensure uniqueness
        vm_args: "rel/vm.args"
      ]
    ]
  end
end
