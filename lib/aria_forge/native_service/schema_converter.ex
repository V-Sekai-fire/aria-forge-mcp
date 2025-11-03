# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaForge.NativeService.SchemaConverter do
  @moduledoc """
  Utilities for converting MCP tool schemas between snake_case and camelCase.
  
  This module handles the conversion of tool definitions to ensure compliance
  with the MCP specification, which requires camelCase keys.
  """

  @doc """
  Converts input_schema to inputSchema in tools/list response.
  """
  def convert_response_keys(%{"jsonrpc" => "2.0", "result" => %{"tools" => tools}} = response) do
    converted_tools = 
      tools
      |> Enum.map(fn tool -> 
          # Handle both map formats (with string or atom keys)
          tool
          |> convert_map_keys()
          |> convert_keys_to_camel_case()
        end)
    Map.put(response, "result", %{"tools" => converted_tools})
  end
  
  def convert_response_keys(response), do: response
  
  @doc false
  defp convert_map_keys(map) when is_map(map) do
    Enum.into(map, %{}, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end
  
  defp convert_map_keys(value), do: value

  @doc """
  Converts snake_case keys to camelCase for MCP spec compliance.
  """
  def convert_keys_to_camel_case(map) when is_map(map) do
    Enum.into(map, %{}, fn
      {:input_schema, value} -> {"inputSchema", convert_keys_to_camel_case(value)}
      {"input_schema", value} -> {"inputSchema", convert_keys_to_camel_case(value)}
      {:inputSchema, value} -> {"inputSchema", convert_keys_to_camel_case(value)}  # Already correct
      {"inputSchema", value} -> {"inputSchema", convert_keys_to_camel_case(value)}  # Already correct
      {:output_schema, value} -> {"outputSchema", convert_keys_to_camel_case(value)}
      {"output_schema", value} -> {"outputSchema", convert_keys_to_camel_case(value)}
      {:outputSchema, value} -> {"outputSchema", convert_keys_to_camel_case(value)}  # Already correct
      {"outputSchema", value} -> {"outputSchema", convert_keys_to_camel_case(value)}  # Already correct
      {key, value} when is_atom(key) -> {Atom.to_string(key), convert_keys_to_camel_case(value)}
      {key, value} -> {key, convert_keys_to_camel_case(value)}
    end)
  end

  def convert_keys_to_camel_case(list) when is_list(list) do
    Enum.map(list, &convert_keys_to_camel_case/1)
  end

  def convert_keys_to_camel_case(value), do: value
end

