# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.BMesh do
  @moduledoc """
  Shared utilities for BMesh operations.
  """

  @doc """
  Ensure Pythonx is available for operations.
  """
  @spec ensure_pythonx() :: :ok | :mock
  def ensure_pythonx do
    # Force mock mode during testing to avoid initialization
    # unless explicitly disabled
    force_mock = Application.get_env(:aria_forge, :force_mock, false) or 
                 (System.get_env("MIX_ENV") == "test" and System.get_env("BYP_MCP_USE_NATIVE") != "true")
    if force_mock do
      :mock
    else
      case Application.ensure_all_started(:pythonx) do
        {:error, _reason} ->
          :mock

        {:ok, _} ->
          check_pythonx_availability()
      end
    end
  rescue
    _ -> :mock
  end

  defp check_pythonx_availability do
    # Python/bpy removed - always return mock
    :mock
  end
end
