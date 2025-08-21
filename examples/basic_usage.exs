#!/usr/bin/env elixir

# Basic usage example for HushOpenbao
# 
# This script demonstrates how to use HushOpenbao to fetch secrets from OpenBao
# 
# Prerequisites:
# 1. OpenBao server running (or use docker: docker run --rm -p 8200:8200 openbao/openbao:latest server -dev)
# 2. Environment variables set:
#    export OPENBAO_ADDR="http://localhost:8200" 
#    export OPENBAO_TOKEN="your-dev-root-token"
#
# Usage: elixir examples/basic_usage.exs

Mix.install([
  {:hush, "~> 1.2"},
  {:hush_openbao, path: "."},
  {:req, "~> 0.5"},
  {:jason, "~> 1.4"}
])

# Configure Hush to use OpenBao provider
Application.put_env(:hush, :providers, [HushOpenbao.Provider])

# Example application configuration using OpenBao secrets
Application.put_env(:example_app, :database, 
  host: {:hush, HushOpenbao.Provider, "myapp/database/host", default: "localhost"},
  port: {:hush, HushOpenbao.Provider, "myapp/database/port", cast: :integer, default: 5432},
  username: {:hush, HushOpenbao.Provider, "myapp/database/username", default: "postgres"},
  password: {:hush, HushOpenbao.Provider, "myapp/database/password"}
)

Application.put_env(:example_app, :external_api,
  api_key: {:hush, HushOpenbao.Provider, "myapp/api/key"},
  base_url: {:hush, HushOpenbao.Provider, "myapp/api/url", default: "https://api.example.com"}
)

# Load secrets from OpenBao
IO.puts("🔐 Loading secrets from OpenBao...")

try do
  # Resolve all configuration containing Hush tuples
  Hush.resolve!()
  
  IO.puts("✅ Successfully loaded secrets!")
  
  # Display the resolved configuration (passwords will be masked)
  database_config = Application.get_env(:example_app, :database)
  api_config = Application.get_env(:example_app, :external_api)
  
  IO.puts("\n📊 Resolved Configuration:")
  IO.puts("Database:")
  IO.puts("  Host: #{database_config[:host]}")
  IO.puts("  Port: #{database_config[:port]}")
  IO.puts("  Username: #{database_config[:username]}")
  IO.puts("  Password: #{"*" |> String.duplicate(String.length(database_config[:password] || ""))}")
  
  IO.puts("\nExternal API:")
  IO.puts("  Base URL: #{api_config[:base_url]}")
  
  if api_config[:api_key] do
    IO.puts("  API Key: #{String.slice(api_config[:api_key], 0..7)}...")
  else
    IO.puts("  API Key: (not found)")
  end
  
rescue
  error ->
    IO.puts("❌ Failed to load secrets: #{inspect(error)}")
    IO.puts("\n💡 Make sure you have:")
    IO.puts("  1. OpenBao server running")
    IO.puts("  2. OPENBAO_ADDR environment variable set")  
    IO.puts("  3. OPENBAO_TOKEN environment variable set")
    IO.puts("  4. Secrets stored in OpenBao at the expected paths:")
    IO.puts("     - myapp/database/password")
    IO.puts("     - myapp/api/key")
    IO.puts("\n📖 See examples/setup_secrets.sh to create test secrets")
end