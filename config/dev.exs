import Config

# Development configuration for HushOpenbao
# Supports both OpenBao and HashiCorp Vault

# Development defaults - good for local testing
config :hush_openbao,
  config: [
    base_url: System.get_env("OPENBAO_ADDR", "http://localhost:8200"),
    token: System.get_env("OPENBAO_TOKEN", "dev-root-token"),
    server_type: System.get_env("OPENBAO_SERVER_TYPE", "openbao") |> String.to_atom(),
    mount_path: System.get_env("OPENBAO_MOUNT_PATH", "secret"),
    version: System.get_env("OPENBAO_KV_VERSION", "v2") |> String.to_atom(),
    timeout: 30_000,
    retry: [delay: 500, max_retries: 3]
  ]
