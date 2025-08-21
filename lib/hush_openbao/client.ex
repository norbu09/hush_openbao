defmodule HushOpenbao.Client do
  @moduledoc """
  HTTP client for OpenBao and HashiCorp Vault APIs using Req.

  This client supports both OpenBao and HashiCorp Vault since they share
  the same API structure (OpenBao is a fork of Vault).
  """

  alias HushOpenbao.Config

  @doc """
  Fetch a secret from OpenBao or Vault.
  """
  @spec fetch_secret(Config.t(), String.t()) ::
          {:ok, String.t()} | {:error, :not_found} | {:error, String.t()}
  def fetch_secret(%Config{} = config, secret_path) do
    url = Config.secret_url(config, secret_path)
    headers = Config.headers(config)

    req_options = [
      headers: headers,
      receive_timeout: config.timeout,
      retry: config.retry,
      retry_log_level: :warning
    ]

    case Req.get(url, req_options) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        parse_secret_response(body, config.version)

      {:ok, %Req.Response{status: 404}} ->
        {:error, :not_found}

      {:ok, %Req.Response{status: 403, body: body}} ->
        error_msg = extract_error_message(body, "Access denied")
        {:error, "Access denied: #{error_msg}"}

      {:ok, %Req.Response{status: 401, body: body}} ->
        error_msg = extract_error_message(body, "Authentication failed")
        {:error, "Authentication failed: #{error_msg}"}

      {:ok, %Req.Response{status: status, body: body}} when status >= 400 ->
        error_msg = extract_error_message(body, "HTTP #{status}")
        server_name = if config.server_type == :vault, do: "Vault", else: "OpenBao"
        {:error, "#{server_name} API error (#{status}): #{error_msg}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "Connection failed: #{format_transport_error(reason)}"}

      {:error, reason} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Test connection to OpenBao or Vault by attempting to read sys/health.
  """
  @spec health_check(Config.t()) :: :ok | {:error, String.t()}
  def health_check(%Config{} = config) do
    url = "#{config.base_url}/v1/sys/health"

    case Req.get(url, receive_timeout: config.timeout) do
      {:ok, %Req.Response{status: status}} when status in [200, 429, 472, 473, 501] ->
        :ok

      {:ok, %Req.Response{status: status, body: body}} ->
        error_msg = extract_error_message(body, "Unhealthy")
        server_name = if config.server_type == :vault, do: "Vault", else: "OpenBao"
        {:error, "#{server_name} health check failed (#{status}): #{error_msg}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, "Connection failed: #{format_transport_error(reason)}"}

      {:error, reason} ->
        {:error, "Health check failed: #{inspect(reason)}"}
    end
  end

  # Parse secret response based on KV version
  defp parse_secret_response(body, :v1) do
    case body do
      %{"data" => data} when is_map(data) ->
        case data do
          %{"value" => value} when is_binary(value) -> {:ok, value}
          data when map_size(data) == 1 -> {:ok, data |> Map.values() |> hd()}
          _ -> {:ok, Jason.encode!(data)}
        end

      _ ->
        {:error, "Invalid secret format"}
    end
  end

  defp parse_secret_response(body, :v2) do
    case body do
      %{"data" => %{"data" => data}} when is_map(data) ->
        case data do
          %{"value" => value} when is_binary(value) -> {:ok, value}
          data when map_size(data) == 1 -> {:ok, data |> Map.values() |> hd()}
          _ -> {:ok, Jason.encode!(data)}
        end

      _ ->
        {:error, "Invalid secret format"}
    end
  end

  # Extract error message from OpenBao API response
  defp extract_error_message(body, default) when is_map(body) do
    cond do
      is_list(body["errors"]) and length(body["errors"]) > 0 ->
        Enum.join(body["errors"], ", ")

      is_binary(body["error"]) ->
        body["error"]

      is_binary(body["message"]) ->
        body["message"]

      true ->
        default
    end
  end

  defp extract_error_message(body, default) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> extract_error_message(decoded, default)
      _ -> default
    end
  end

  defp extract_error_message(_, default), do: default

  # Format transport errors for better user experience
  defp format_transport_error(:timeout), do: "request timeout"
  defp format_transport_error(:nxdomain), do: "domain not found"
  defp format_transport_error(:econnrefused), do: "connection refused"
  defp format_transport_error(:ehostunreach), do: "host unreachable"
  defp format_transport_error(reason), do: inspect(reason)
end
