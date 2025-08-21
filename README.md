# HushOpenbao

[![Build Status](https://img.shields.io/github/actions/workflow/status/gordalina/hush_openbao/ci.yml?branch=main&style=flat-square)](https://github.com/gordalina/hush_openbao/actions/workflows/ci.yml)
[![Coverage Status](https://img.shields.io/codecov/c/github/gordalina/hush_openbao?style=flat-square)](https://app.codecov.io/gh/gordalina/hush_openbao)
[![hex.pm version](https://img.shields.io/hexpm/v/hush_openbao?style=flat-square)](https://hex.pm/packages/hush_openbao)

An OpenBao provider for [Hush](https://hex.pm/packages/hush) - retrieve secrets from OpenBao at runtime.

HushOpenbao allows you to retrieve secrets from [OpenBao](https://openbao.org/) seamlessly within your Elixir application's configuration system, enabling secure secret management without hardcoding sensitive data.

## Installation

Add `hush_openbao` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hush, "~> 1.2"},
    {:hush_openbao, "~> 0.1"}
  ]
end
```

## Quick Start

### 1. Configure OpenBao Connection

Set up your OpenBao connection using environment variables:

```bash
export OPENBAO_ADDR="https://vault.example.com"
export OPENBAO_TOKEN="hvs.your_token_here"
```

Or via application configuration:

```elixir
# config/config.exs
config :hush_openbao,
  config: [
    base_url: "https://vault.example.com",
    token: "hvs.your_token_here"
  ]
```

### 2. Register the Provider

Add HushOpenbao.Provider to your Hush providers list:

```elixir
# config/config.exs
config :hush,
  providers: [HushOpenbao.Provider]
```

### 3. Use OpenBao Secrets in Configuration

Reference secrets in your application configuration using the Hush tuple format:

```elixir
# config/prod.exs
config :myapp,
  database_password: {:hush, HushOpenbao.Provider, "myapp/database/password"},
  api_key: {:hush, HushOpenbao.Provider, "myapp/external/api_key", default: "fallback"},
  ssl_cert: {:hush, HushOpenbao.Provider, "myapp/ssl/certificate", to_file: "/tmp/cert.pem"}
```

### 4. Initialize Hush

Load your configuration at runtime:

```elixir
# In your application.ex
def start(_type, _args) do
  # Load secrets at startup (runtime mode)
  unless Hush.release_mode?(), do: Hush.resolve!()
  
  # ... rest of your application startup
end
```

Or use release mode (recommended for production):

```elixir
# mix.exs
def project do
  [
    # ...
    releases: [
      myapp: [
        config_providers: [{Hush.ConfigProvider, nil}]
      ]
    ]
  ]
end
```

## Configuration

### Environment Variables

- `OPENBAO_ADDR` - OpenBao server URL (required)
- `OPENBAO_TOKEN` - Authentication token (required if no token file)
- `OPENBAO_TOKEN_FILE` - Path to file containing token (alternative to OPENBAO_TOKEN)
- `OPENBAO_MOUNT_PATH` - KV secrets engine mount path (default: "secret")
- `OPENBAO_KV_VERSION` - KV engine version: "v1" or "v2" (default: "v2")
- `OPENBAO_TIMEOUT` - Request timeout in milliseconds (default: 30000)

### Application Configuration

```elixir
config :hush_openbao,
  config: [
    base_url: "https://vault.example.com",
    token: "hvs.your_token_here",
    # or token_file: "/var/run/secrets/vault-token"
    mount_path: "secret",
    version: :v2,
    timeout: 30_000,
    retry: [delay: 500, max_retries: 3]
  ]
```

## Supported Secret Engines

### KV Version 2 (Recommended)

KV v2 provides versioned key-value storage with metadata:

```elixir
# Secret path: secret/data/myapp/database
config :myapp,
  password: {:hush, HushOpenbao.Provider, "myapp/database"}
```

### KV Version 1

KV v1 provides simple key-value storage:

```elixir
# Configure to use KV v1
config :hush_openbao,
  config: [version: :v1]

# Secret path: secret/myapp/database
config :myapp,
  password: {:hush, HushOpenbao.Provider, "myapp/database"}
```

## Secret Formats

### Single Value Secrets

For secrets with a single `value` field:

```json
{
  "value": "my-secret-password"
}
```

The provider returns the string value directly: `"my-secret-password"`

### Multi-Value Secrets

For secrets with multiple fields:

```json
{
  "username": "admin",
  "password": "secret123",
  "host": "db.example.com"
}
```

The provider returns a JSON string containing all fields.

### Single Field Secrets

For secrets with one custom field:

```json
{
  "api_key": "sk_live_abcd1234"
}
```

The provider returns the field value directly: `"sk_live_abcd1234"`

## Advanced Usage

### Custom Mount Paths

If your secrets are mounted at a different path:

```elixir
config :hush_openbao,
  config: [mount_path: "kv-prod"]

# This will fetch from: /v1/kv-prod/data/myapp/secret
config :myapp,
  secret: {:hush, HushOpenbao.Provider, "myapp/secret"}
```

### Token from File

For container environments where tokens are mounted as files:

```elixir
config :hush_openbao,
  config: [token_file: "/var/run/secrets/vault-token"]
```

### Retry Configuration

Configure retry behavior for failed requests:

```elixir
config :hush_openbao,
  config: [
    retry: [
      delay: 1000,        # Initial delay between retries (ms)
      max_retries: 5      # Maximum number of retries
    ]
  ]
```

### Using with Hush Transformers

Combine with Hush's built-in transformers:

```elixir
config :myapp,
  # Cast to integer
  pool_size: {:hush, HushOpenbao.Provider, "myapp/pool_size", cast: :integer},
  
  # Write to file
  ssl_cert: {:hush, HushOpenbao.Provider, "myapp/ssl/cert", to_file: "/tmp/cert.pem"},
  
  # Apply custom transformation
  base_url: {:hush, HushOpenbao.Provider, "myapp/host", apply: &transform_url/1}

defp transform_url(host), do: {:ok, "https://#{host}"}
```

## Error Handling

The provider handles various error conditions gracefully:

### Missing Secrets
```elixir
# Returns {:error, :not_found} - handled by Hush
config :myapp,
  optional_key: {:hush, HushOpenbao.Provider, "missing/key", optional: true}
```

### Authentication Errors
- Invalid tokens result in helpful error messages
- Permission denied errors include the specific issue

### Network Issues
- Connection failures are clearly reported
- Timeouts and DNS issues are handled appropriately

### Secret Format Issues
- Invalid JSON responses are caught and reported
- Unexpected secret structures return descriptive errors

## Development

### Running Tests

```bash
mix deps.get
mix test
```

### Type Checking

```bash
mix dialyzer
```

### Linting

```bash
mix credo
mix sobelow
```

## Examples

### Basic Web Application

```elixir
# config/prod.exs
config :hush,
  providers: [HushOpenbao.Provider]

config :myapp, MyApp.Repo,
  username: "myapp_user",
  password: {:hush, HushOpenbao.Provider, "myapp/database/password"},
  hostname: {:hush, HushOpenbao.Provider, "myapp/database/hostname"},
  port: {:hush, HushOpenbao.Provider, "myapp/database/port", cast: :integer}

config :myapp, MyApp.ExternalAPI,
  api_key: {:hush, HushOpenbao.Provider, "myapp/external/api_key"},
  webhook_secret: {:hush, HushOpenbao.Provider, "myapp/external/webhook_secret"}
```

### Microservice with Multiple Secrets

```elixir
# config/runtime.exs (for releases)
import Config

if config_env() == :prod do
  config :hush,
    providers: [HushOpenbao.Provider]

  config :myapp,
    # Database credentials
    database_url: {:hush, HushOpenbao.Provider, "myapp/database_url"},
    
    # External service credentials  
    redis_url: {:hush, HushOpenbao.Provider, "myapp/redis_url"},
    s3_access_key: {:hush, HushOpenbao.Provider, "myapp/s3/access_key"},
    s3_secret_key: {:hush, HushOpenbao.Provider, "myapp/s3/secret_key"},
    
    # SSL certificates
    ssl_keyfile: {:hush, HushOpenbao.Provider, "myapp/ssl/private_key", to_file: "/tmp/ssl.key"},
    ssl_certfile: {:hush, HushOpenbao.Provider, "myapp/ssl/certificate", to_file: "/tmp/ssl.crt"},
    
    # Feature flags and configuration
    feature_flags: {:hush, HushOpenbao.Provider, "myapp/feature_flags", cast: :string, apply: &Jason.decode!/1},
    rate_limit: {:hush, HushOpenbao.Provider, "myapp/rate_limit", cast: :integer, default: 100}
end
```

## Security Considerations

1. **Token Security**: Never commit tokens to version control. Use environment variables or secure token files.

2. **Network Security**: Always use HTTPS for OpenBao connections in production.

3. **Token Rotation**: Implement token rotation strategies for long-running applications.

4. **Least Privilege**: Configure OpenBao policies to grant minimal required permissions.

5. **Audit Logging**: Enable OpenBao audit logging to track secret access.

## Troubleshooting

### Connection Issues

```elixir
# Test your connection
iex> HushOpenbao.Provider.load([
  base_url: "https://vault.example.com",
  token: "your_token"
])
{:ok}  # or {:error, "Connection failed: ..."}
```

### Secret Path Issues

Verify your secret paths match your OpenBao configuration:
- KV v2: `/v1/{mount}/data/{path}`
- KV v1: `/v1/{mount}/{path}`

### Permission Issues

Check your token has appropriate policies:
```bash
vault token lookup  # Check token info
vault policy read your-policy  # Check policy permissions
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write tests for your changes
4. Run the test suite (`mix test`)
5. Run code quality checks (`mix credo && mix dialyzer`)
6. Commit your changes (`git commit -am 'Add some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create a new Pull Request

## License

HushOpenbao is released under the Apache License 2.0 - see the [LICENSE](LICENSE) file.

## Related Projects

- [Hush](https://github.com/gordalina/hush) - Extensible runtime configuration loader
- [hush_aws_secrets_manager](https://github.com/gordalina/hush_aws_secrets_manager) - AWS Secrets Manager provider
- [hush_gcp_secret_manager](https://github.com/gordalina/hush_gcp_secret_manager) - Google Cloud Secret Manager provider
- [OpenBao](https://openbao.org/) - Open source secrets management platform