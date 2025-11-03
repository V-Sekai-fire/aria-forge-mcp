# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Objects do
  @moduledoc """
  Object creation tools for (cubes, spheres, etc.)
  """

  alias AriaForge.Tools.Utils

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Creates a cube object in the scene.
  """
  @spec create_cube(String.t(), [number()], number(), String.t()) :: result()
  def create_cube(name \\ "Cube", location \\ [0, 0, 0], size \\ 2.0, temp_dir) do
    mock_create_cube(name, location, size)
  end

  defp mock_create_cube(name, location, size) do
    {:ok, "Created cube '#{name}' at #{inspect(location)} with size #{size}"}
  end

  @doc """
  Creates a sphere object in the scene.
  """
  @spec create_sphere(String.t(), [number()], number(), String.t()) :: result()
  def create_sphere(name \\ "Sphere", location \\ [0, 0, 0], radius \\ 1.0, temp_dir) do
    mock_create_sphere(name, location, radius)
  end

  defp mock_create_sphere(name, location, radius) do
    {:ok, "Created sphere '#{name}' at #{inspect(location)} with radius #{radius}"}
  end

  # Test helper functions
  @doc false
  def test_mock_create_cube(name, location, size), do: mock_create_cube(name, location, size)
  @doc false
  def test_mock_create_sphere(name, location, radius), do: mock_create_sphere(name, location, radius)
end

