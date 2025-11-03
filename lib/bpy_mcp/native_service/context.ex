# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule BpyMcp.NativeService.Context do
  @moduledoc """
  Context management for Blender scene operations.
  
  This module handles creation and retrieval of scene contexts, including
  encoding/decoding context tokens (macaroons) that store PID and metadata.
  """

  @doc """
  Get or create a context from token or scene_id.
  
  Returns `{:ok, temp_dir, pid}` or `{:error, reason}`.
  """
  def get_or_create_context(args, state) do
    # Try to get context from token first
    context_token = Map.get(args, "context_token") || Map.get(state, :context_token)
    scene_id = Map.get(args, "scene_id", "default")

    case context_token do
      nil ->
        # No token, create or get context by scene_id
        create_or_get_context(scene_id, state)

      token when is_binary(token) ->
        # Decode token to get PID
        case decode_context_token(token) do
          {:ok, %{pid: pid, metadata: _metadata}} ->
            # Verify PID is still alive
            if Process.alive?(pid) do
              # Get or create temp_dir for this context
              temp_dir = Map.get(state, :temp_dir) || create_temp_dir()
              {:ok, temp_dir, pid}
            else
              # PID is dead, create new context
              create_or_get_context(scene_id, state)
            end

          {:error, _reason} ->
            # Token invalid, create new context
            create_or_get_context(scene_id, state)
        end
    end
  end

  @doc false
  defp create_or_get_context(scene_id, state) do
    case BpyMcp.set_context(scene_id) do
      {:ok, pid} ->
        # Create temp_dir for this context
        temp_dir = Map.get(state, :temp_dir) || create_temp_dir()
        
        # Encode context token
        case encode_context_token(pid, %{scene_id: scene_id, operation_count: 0}) do
          {:ok, _token} ->
            {:ok, temp_dir, pid}
          _ ->
            {:ok, temp_dir, pid}
        end

      {:error, reason} ->
        {:error, "Failed to create context: #{reason}"}
    end
  end

  @doc """
  Get scene_id from PID.
  """
  def get_scene_id(pid) do
    try do
      BpyMcp.SceneManager.get_scene_id(pid)
    rescue
      _ -> "default"
    end
  end

  @doc """
  Create a temporary directory for scene operations.
  """
  def create_temp_dir do
    temp_path = System.tmp_dir!() <> "/bpy_mcp_" <> Base.encode16(:crypto.strong_rand_bytes(8))
    case File.mkdir_p(temp_path) do
      :ok -> temp_path
      {:error, _} -> System.tmp_dir!()
    end
  end

  @doc """
  Encodes PID and metadata into a macaroon token for context strings.
  
  ## Parameters
    - pid: Process ID to encode
    - metadata: Map of additional context data (scene_id, operation_count, etc.)
  
  ## Returns
    - `{:ok, token}` - Base64-encoded macaroon token containing PID data
    - `{:error, reason}` - Error if encoding fails
  """
  @spec encode_context_token(pid(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def encode_context_token(pid, metadata) when is_pid(pid) do
    try do
      # Serialize PID and metadata as JSON for storage in caveat
      pid_str = :erlang.pid_to_list(pid) |> List.to_string()
      data = Map.merge(metadata, %{pid: pid_str})
      data_json = Jason.encode!(data)
      
      # Create macaroon with context data stored in location and as encoded data
      location = "bpy-mcp-context"
      secret_key = get_or_create_secret_key()
      
      # Generate a unique kid (key ID) - we'll store the data in a Mutations caveat
      # Mutations caveat accepts a list of strings, so we'll encode our JSON as base64
      kid = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
      
      # Store PID data in a Mutations caveat (which accepts list of strings)
      # Encode the JSON data and store it as a mutation entry
      encoded_data = Base.encode64(data_json)
      # Use struct construction at runtime to avoid compile-time dependency issues
      context_caveat = struct(Macfly.Caveat.Mutations, mutations: [encoded_data])
      
      # Create macaroon with the caveat containing our context data
      macaroon = Macfly.Macaroon.new(secret_key, kid, location, [context_caveat])
      
      # Encode macaroon to string
      token = Macfly.Macaroon.encode(macaroon)
      {:ok, token}
    rescue
      e -> {:error, "Failed to encode context token: #{Exception.message(e)}"}
    end
  end

  @doc """
  Decodes a macaroon token to extract PID and metadata from context string.
  
  ## Parameters
    - token: Base64-encoded macaroon token
  
  ## Returns
    - `{:ok, %{pid: pid(), metadata: map()}}` - Decoded PID and metadata
    - `{:error, reason}` - Error if decoding fails
  """
  @spec decode_context_token(String.t()) :: {:ok, %{pid: pid(), metadata: map()}} | {:error, String.t()}
  def decode_context_token(token) when is_binary(token) do
    try do
      # Decode macaroon from string
      case Macfly.Macaroon.decode(token) do
        {:ok, macaroon} ->
          # Extract PID data from Mutations caveat
          mutations_caveat = 
            Enum.find(macaroon.caveats, fn caveat ->
              case caveat do
                %Macfly.Caveat.Mutations{} -> true
                _ -> false
              end
            end)
          
          case mutations_caveat do
            nil ->
              {:error, "No context data found in token"}
            
            %Macfly.Caveat.Mutations{mutations: [encoded_data | _]} ->
              # Decode the base64-encoded JSON data
              case Base.decode64(encoded_data) do
                {:ok, data_json} ->
                  case Jason.decode(data_json) do
                    {:ok, data} ->
                      pid_str = Map.get(data, "pid")
                      
                      # Convert PID string back to PID
                      pid = 
                        try do
                          :erlang.list_to_pid(String.to_charlist(pid_str))
                        rescue
                          _ -> {:error, "Invalid PID format"}
                        end
                      
                      case pid do
                        {:error, reason} -> {:error, reason}
                        pid when is_pid(pid) ->
                          metadata = Map.drop(data, ["pid"])
                          {:ok, %{pid: pid, metadata: metadata}}
                        _ ->
                          {:error, "Failed to parse PID"}
                      end
                    
                    error ->
                      {:error, "Failed to decode PID data: #{inspect(error)}"}
                  end
                
                :error ->
                  {:error, "Invalid token format: context data is not base64 encoded"}
              end
            
            _ ->
              {:error, "Invalid Mutations caveat format"}
          end
        
        error ->
          {:error, "Failed to decode macaroon: #{inspect(error)}"}
      end
    rescue
      e -> {:error, "Failed to decode context token: #{Exception.message(e)}"}
    end
  end

  @doc false
  # Get or create a secret key for macaroon signing
  # In production, this should be configured via environment variable or config
  # In development, generates and persists a key in ~/.bpy_mcp/macaroon_secret
  defp get_or_create_secret_key do
    # First, try explicit configuration
    case Application.get_env(:bpy_mcp, :macaroon_secret_key) do
      nil ->
        # Try environment variable
        case System.get_env("BPY_MCP_MACAROON_SECRET") do
          nil ->
            # Generate and persist a key for development
            secret_file = Path.join(System.user_home!(), ".bpy_mcp/macaroon_secret")
            secret_dir = Path.dirname(secret_file)
            
            # Ensure directory exists
            File.mkdir_p!(secret_dir)
            
            # Read existing or generate new secret
            case File.read(secret_file) do
              {:ok, existing_secret} when byte_size(existing_secret) == 32 ->
                existing_secret
              
              _ ->
                # Generate new secret
                secret = :crypto.strong_rand_bytes(32)
                File.write!(secret_file, secret, [:binary, :exclusive])
                secret
            end
          
          env_secret ->
            env_secret
        end
      
      configured_secret when is_binary(configured_secret) ->
        configured_secret
      
      _ ->
        # Fallback to random (non-persistent)
        :crypto.strong_rand_bytes(32)
    end
  end
end

