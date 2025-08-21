import Config

# Test configuration for HushOpenbao
# This file is loaded for the test environment

# Configure test environment to use different OpenBao instance
config :hush_openbao,
  config: [
    base_url: System.get_env("TEST_OPENBAO_ADDR", "http://localhost:8201"),
    token: System.get_env("TEST_OPENBAO_TOKEN", "test-token"),
    mount_path: "test-secrets",
    version: :v2,
    timeout: 5000,
    retry: [delay: 100, max_retries: 2]
  ]

# Configure ExUnit
config :ex_unit,
  capture_log: true
