# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.Tools.Planning.Utils do
  @moduledoc """
  Utility functions for planning operations.
  """

  @doc """
  Converts seconds to ISO 8601 duration string.
  
  Examples:
  - 1 second -> "PT1S"
  - 30 seconds -> "PT30S"
  - 90 seconds -> "PT1M30S"
  - 3600 seconds -> "PT1H"
  """
  @spec seconds_to_iso_duration(float() | integer()) :: String.t()
  def seconds_to_iso_duration(seconds) when is_float(seconds) or is_integer(seconds) do
    total_seconds = trunc(seconds)
    
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    secs = rem(total_seconds, 60)
    
    parts = []
    parts = if hours > 0, do: ["#{hours}H" | parts], else: parts
    parts = if minutes > 0, do: ["#{minutes}M" | parts], else: parts
    parts = if secs > 0, do: ["#{secs}S" | parts], else: parts
    
    # Always include at least seconds, even if 0
    if Enum.empty?(parts), do: "PT0S", else: "PT" <> Enum.join(parts)
  end

  @doc """
  Returns a complexity label based on operation count.
  """
  @spec complexity_label(integer()) :: String.t()
  def complexity_label(count) when count < 5, do: "simple"
  def complexity_label(count) when count < 15, do: "moderate"
  def complexity_label(count) when count < 30, do: "complex"
  def complexity_label(_), do: "very_complex"

end

