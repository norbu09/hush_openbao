defmodule HushOpenbao.Provider do
  @moduledoc """
  Implements a Hush.Provider behaviour to resolve secrets from
  OpenBao or HashiCorp Vault at runtime.

  To configure this provider, set the required environment variables
  or configure the application:

      # Via environment variables
      export OPENBAO_ADDR="https://vault.example.com"
      export OPENBAO_TOKEN="hvs.your_token_here"
      export OPENBAO_SERVER_TYPE="vault"     # optional, defaults to "openbao"
      export OPENBAO_MOUNT_PATH="secret"     # optional, defaults to "secret"
      export OPENBAO_KV_VERSION="v2"         # optional, defaults to "v2"

      # Or via application config
      config :hush_openbao,
        config: [
          base_url: "https://vault.example.com",
          token: "hvs.your_token_here",
          server_type: :vault,  # or :openbao (default)
          mount_path: "secret",
          version: :v2
        ]

      # Then configure hush to use this provider
      config :hush,
        providers: [HushOpenbao.Provider]

  Usage in configuration:

      config :myapp,
        database_password: {:hush, HushOpenbao.Provider, "myapp/database/password"}
  """

  alias HushOpenbao.{Client, Config}

  @behaviour Hush.Provider

  @impl Hush.Provider
  @spec load(config :: Keyword.t()) :: :ok | {:error, any()}
  def load(config) do
    with {:ok, openbao_config} <- Config.load(config),
         :ok <- Client.health_check(openbao_config) do
      # Store config in process dictionary for use in fetch/1
      Process.put(__MODULE__, openbao_config)
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl Hush.Provider
  @spec fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found} | {:error, any()}
  def fetch(key) do
    case Process.get(__MODULE__) do
      %Config{} = config ->
        Client.fetch_secret(config, key)

      nil ->
        {:error, "OpenBao provider not loaded. Ensure it's configured in :hush providers list."}
    end
  end
end
