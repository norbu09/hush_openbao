import Config

# Production configuration for HushOpenbao
# Supports both OpenBao and HashiCorp Vault

# Production configuration - requires environment variables to be set
config :hush_openbao,
  config: [
    # These must be set via environment variables in production
    base_url:
      System.get_env("OPENBAO_ADDR") ||
        raise("OPENBAO_ADDR environment variable is required in production"),
    token: System.get_env("OPENBAO_TOKEN"),
    token_file: System.get_env("OPENBAO_TOKEN_FILE"),
    server_type: System.get_env("OPENBAO_SERVER_TYPE", "openbao") |> String.to_atom(),
    mount_path: System.get_env("OPENBAO_MOUNT_PATH", "secret"),
    version: System.get_env("OPENBAO_KV_VERSION", "v2") |> String.to_atom(),
    timeout: System.get_env("OPENBAO_TIMEOUT", "30000") |> String.to_integer(),
    retry: [
      delay: System.get_env("OPENBAO_RETRY_DELAY", "1000") |> String.to_integer(),
      max_retries: System.get_env("OPENBAO_MAX_RETRIES", "5") |> String.to_integer()
    ]
  ]

# Validate that either token or token_file is provided
unless System.get_env("OPENBAO_TOKEN") || System.get_env("OPENBAO_TOKEN_FILE") do
  raise "Either OPENBAO_TOKEN or OPENBAO_TOKEN_FILE environment variable is required in production"
end
