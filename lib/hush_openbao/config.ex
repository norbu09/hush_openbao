defmodule HushOpenbao.Config do
  @moduledoc """
  Configuration management for HushOpenbao provider.
  """

  @type t :: %__MODULE__{
          base_url: String.t(),
          token: String.t() | nil,
          mount_path: String.t(),
          version: :v1 | :v2,
          timeout: pos_integer(),
          retry: Keyword.t(),
          server_type: :openbao | :vault
        }

  defstruct base_url: "http://localhost:8200",
            token: nil,
            mount_path: "secret",
            version: :v2,
            timeout: 30_000,
            retry: [delay: 500, max_retries: 3],
            server_type: :openbao

  @doc """
  Load configuration from application environment and system environment.
  """
  @spec load(Keyword.t()) :: {:ok, t()} | {:error, String.t()}
  def load(config \\ []) do
    app_config = Application.get_env(:hush_openbao, :config, [])
    merged_config = Keyword.merge(app_config, config)

    with {:ok, base_url} <- get_base_url(merged_config),
         {:ok, token} <- get_token(merged_config),
         {:ok, mount_path} <- get_mount_path(merged_config),
         {:ok, version} <- get_version(merged_config),
         {:ok, timeout} <- get_timeout(merged_config),
         {:ok, retry} <- get_retry(merged_config),
         {:ok, server_type} <- get_server_type(merged_config) do
      {:ok,
       %__MODULE__{
         base_url: base_url,
         token: token,
         mount_path: mount_path,
         version: version,
         timeout: timeout,
         retry: retry,
         server_type: server_type
       }}
    end
  end

  defp get_base_url(config) do
    case get_config_value(config, :base_url, "OPENBAO_ADDR") do
      nil -> {:error, "base_url is required. Set OPENBAO_ADDR or configure :base_url"}
      url when is_binary(url) -> {:ok, String.trim_trailing(url, "/")}
      _ -> {:error, "base_url must be a string"}
    end
  end

  defp get_token(config) do
    case get_config_value(config, :token, "OPENBAO_TOKEN") do
      nil ->
        case get_config_value(config, :token_file, "OPENBAO_TOKEN_FILE") do
          nil -> {:error, "token is required. Set OPENBAO_TOKEN or configure :token"}
          token_file -> read_token_file(token_file)
        end

      token when is_binary(token) ->
        {:ok, token}

      _ ->
        {:error, "token must be a string"}
    end
  end

  defp get_mount_path(config) do
    mount_path = get_config_value(config, :mount_path, "OPENBAO_MOUNT_PATH", "secret")
    {:ok, mount_path}
  end

  defp get_version(config) do
    version_str = get_config_value(config, :version, "OPENBAO_KV_VERSION", "v2")

    case version_str do
      "v1" -> {:ok, :v1}
      "v2" -> {:ok, :v2}
      :v1 -> {:ok, :v1}
      :v2 -> {:ok, :v2}
      _ -> {:error, "version must be 'v1' or 'v2'"}
    end
  end

  defp get_timeout(config) do
    timeout = get_config_value(config, :timeout, "OPENBAO_TIMEOUT", "30000")

    case timeout do
      t when is_integer(t) and t > 0 -> {:ok, t}
      t when is_binary(t) -> parse_integer(t, "timeout")
      _ -> {:error, "timeout must be a positive integer"}
    end
  end

  defp get_retry(config) do
    retry = Keyword.get(config, :retry, delay: 500, max_retries: 3)
    {:ok, retry}
  end

  defp get_server_type(config) do
    server_type_str = get_config_value(config, :server_type, "OPENBAO_SERVER_TYPE", "openbao")

    case server_type_str do
      "openbao" -> {:ok, :openbao}
      "vault" -> {:ok, :vault}
      :openbao -> {:ok, :openbao}
      :vault -> {:ok, :vault}
      _ -> {:error, "server_type must be 'openbao' or 'vault'"}
    end
  end

  defp get_config_value(config, key, env_var, default \\ nil) do
    case Keyword.get(config, key) do
      nil -> System.get_env(env_var, default)
      value -> value
    end
  end

  defp read_token_file(token_file) do
    case File.read(token_file) do
      {:ok, content} -> {:ok, String.trim(content)}
      {:error, reason} -> {:error, "Could not read token file #{token_file}: #{reason}"}
    end
  end

  defp parse_integer(str, field_name) do
    case Integer.parse(str) do
      {int, ""} when int > 0 -> {:ok, int}
      _ -> {:error, "#{field_name} must be a positive integer"}
    end
  end

  @doc """
  Build the full URL for accessing a secret.
  """
  @spec secret_url(t(), String.t()) :: String.t()
  def secret_url(
        %__MODULE__{base_url: base_url, mount_path: mount_path, version: version},
        secret_path
      ) do
    case version do
      :v1 -> "#{base_url}/v1/#{mount_path}/#{secret_path}"
      :v2 -> "#{base_url}/v1/#{mount_path}/data/#{secret_path}"
    end
  end

  @doc """
  Get request headers for OpenBao API calls.
  """
  @spec headers(t()) :: list({String.t(), String.t()})
  def headers(%__MODULE__{token: token}) do
    [
      {"X-Vault-Token", token},
      {"Content-Type", "application/json"}
    ]
  end
end
