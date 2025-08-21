defmodule HushOpenbao do
  @moduledoc """
  HushOpenbao provides an OpenBao and HashiCorp Vault provider for the Hush configuration library.

  This library allows you to retrieve secrets from OpenBao or HashiCorp Vault at runtime,
  integrating seamlessly with Elixir's configuration system through Hush.
  
  Both OpenBao and Vault are supported since they share the same API structure
  (OpenBao is a fork of Vault).

  ## Quick Start

  1. Configure your OpenBao or Vault connection:

      ```bash
      export OPENBAO_ADDR="https://vault.example.com"
      export OPENBAO_TOKEN="hvs.your_token_here"
      # Optional: specify server type (defaults to "openbao")
      export OPENBAO_SERVER_TYPE="vault"
      ```

  2. Add the provider to your Hush configuration:

      ```elixir
      # config/config.exs
      config :hush,
        providers: [HushOpenbao.Provider]
      ```

  3. Use OpenBao or Vault secrets in your application configuration:

      ```elixir
      # config/prod.exs
      config :myapp,
        database_password: {:hush, HushOpenbao.Provider, "myapp/database/password"},
        api_key: {:hush, HushOpenbao.Provider, "myapp/api_key", default: "fallback"}
      ```

  ## Configuration

  The provider can be configured via environment variables or application config:

  ### Environment Variables
  - `OPENBAO_ADDR` - OpenBao or Vault server URL (required)
  - `OPENBAO_TOKEN` - Authentication token (required)
  - `OPENBAO_TOKEN_FILE` - Path to token file (alternative to OPENBAO_TOKEN)
  - `OPENBAO_SERVER_TYPE` - Server type: "openbao" or "vault" (default: "openbao")
  - `OPENBAO_MOUNT_PATH` - KV mount path (default: "secret")
  - `OPENBAO_KV_VERSION` - KV engine version "v1" or "v2" (default: "v2")
  - `OPENBAO_TIMEOUT` - Request timeout in milliseconds (default: 30000)

  ### Application Config

      ```elixir
      config :hush_openbao,
        config: [
          base_url: "https://vault.example.com",
          token: "hvs.your_token_here",
          server_type: :vault,  # or :openbao (default)
          mount_path: "secret",
          version: :v2,
          timeout: 30_000,
          retry: [delay: 500, max_retries: 3]
        ]
      ```

  ## Usage with Hush

  See the [Hush documentation](https://hexdocs.pm/hush) for detailed usage patterns.

  ## Supported Secret Engines

  - **KV v1**: Simple key-value storage
  - **KV v2**: Versioned key-value storage (recommended)

  ## Error Handling

  The provider handles various error conditions:
  - Network connectivity issues
  - Authentication failures
  - Missing secrets
  - Invalid secret formats
  - OpenBao/Vault server errors
  """

  alias HushOpenbao.Provider

  @doc """
  Convenience function to access the main provider module.
  """
  defdelegate load(config), to: Provider
  defdelegate fetch(key), to: Provider
end
