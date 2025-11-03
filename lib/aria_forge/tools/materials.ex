# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Materials do
  @moduledoc """
  Material manipulation tools for objects.
  """

  alias AriaForge.Tools.Utils

  @type result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Sets a material on an object.
  """
  @spec set_material(String.t(), String.t(), [number()], String.t()) :: result()
  def set_material(object_name, material_name \\ "Material", color \\ [0.8, 0.8, 0.8, 1.0], temp_dir) do
    mock_set_material(object_name, material_name, color)
  end

  defp mock_set_material(object_name, material_name, color) do
    {:ok, "Set material '#{material_name}' with color #{inspect(color)} on object '#{object_name}'"}
  end

  # Test helper function
  @doc false
  def test_mock_set_material(object_name, material_name, color),
    do: mock_set_material(object_name, material_name, color)
end

