defmodule HushOpenbao.ConfigTest do
  use ExUnit.Case, async: false

  alias HushOpenbao.Config

  setup do
    # Clean up any previous app config and environment variables
    Application.delete_env(:hush_openbao, :config)

    # Clean up environment variables that might affect tests
    env_vars = [
      "OPENBAO_ADDR",
      "OPENBAO_TOKEN",
      "OPENBAO_TOKEN_FILE",
      "OPENBAO_MOUNT_PATH",
      "OPENBAO_KV_VERSION",
      "OPENBAO_TIMEOUT"
    ]

    for var <- env_vars do
      System.delete_env(var)
    end

    :ok
  end

  describe "load/1" do
    test "loads default configuration" do
      System.put_env("OPENBAO_ADDR", "http://localhost:8200")
      System.put_env("OPENBAO_TOKEN", "test-token")

      assert {:ok, config} = Config.load()
      assert config.base_url == "http://localhost:8200"
      assert config.token == "test-token"
      assert config.mount_path == "secret"
      assert config.version == :v2
      assert config.timeout == 30_000
      assert config.server_type == :openbao

      System.delete_env("OPENBAO_ADDR")
      System.delete_env("OPENBAO_TOKEN")
    end

    test "loads configuration from app config" do
      config_opts = [
        base_url: "https://vault.example.com",
        token: "app-token",
        mount_path: "kv",
        version: :v1,
        timeout: 60_000,
        server_type: :vault
      ]

      assert {:ok, config} = Config.load(config_opts)
      assert config.base_url == "https://vault.example.com"
      assert config.token == "app-token"
      assert config.mount_path == "kv"
      assert config.version == :v1
      assert config.timeout == 60_000
      assert config.server_type == :vault
    end

    test "environment variables override app config" do
      System.put_env("OPENBAO_ADDR", "http://env.example.com")
      System.put_env("OPENBAO_TOKEN", "env-token")

      # Pass empty config to force environment variable reading
      assert {:ok, config} = Config.load([])
      assert config.base_url == "http://env.example.com"
      assert config.token == "env-token"

      System.delete_env("OPENBAO_ADDR")
      System.delete_env("OPENBAO_TOKEN")
    end

    test "trims trailing slash from base_url" do
      config_opts = [base_url: "https://vault.example.com/", token: "test"]

      assert {:ok, config} = Config.load(config_opts)
      assert config.base_url == "https://vault.example.com"
    end

    test "returns error when base_url is missing" do
      assert {:error, error} = Config.load()
      assert error =~ "base_url is required"
    end

    test "returns error when token is missing" do
      config_opts = [base_url: "https://vault.example.com"]

      assert {:error, error} = Config.load(config_opts)
      assert error =~ "token is required"
    end

    test "loads token from file" do
      token_content = "file-token-content"
      token_file = Path.join(System.tmp_dir(), "test_token")
      File.write!(token_file, "  #{token_content}  \n")

      config_opts = [
        base_url: "https://vault.example.com",
        token_file: token_file
      ]

      assert {:ok, config} = Config.load(config_opts)
      assert config.token == token_content

      File.rm!(token_file)
    end

    test "returns error when token file doesn't exist" do
      config_opts = [
        base_url: "https://vault.example.com",
        token_file: "/non/existent/file"
      ]

      assert {:error, error} = Config.load(config_opts)
      assert error =~ "Could not read token file"
    end

    test "validates version parameter" do
      base_config = [base_url: "https://vault.example.com", token: "test"]

      assert {:ok, config} = Config.load(base_config ++ [version: :v1])
      assert config.version == :v1

      assert {:ok, config} = Config.load(base_config ++ [version: "v2"])
      assert config.version == :v2

      assert {:error, error} = Config.load(base_config ++ [version: "invalid"])
      assert error =~ "version must be 'v1' or 'v2'"
    end

    test "validates timeout parameter" do
      base_config = [base_url: "https://vault.example.com", token: "test"]

      assert {:ok, config} = Config.load(base_config ++ [timeout: 5000])
      assert config.timeout == 5000

      assert {:error, error} = Config.load(base_config ++ [timeout: -1])
      assert error =~ "timeout must be a positive integer"

      assert {:error, error} = Config.load(base_config ++ [timeout: "invalid"])
      assert error =~ "timeout must be a positive integer"
    end

    test "parses timeout from environment variable" do
      System.put_env("OPENBAO_ADDR", "http://localhost:8200")
      System.put_env("OPENBAO_TOKEN", "test-token")
      System.put_env("OPENBAO_TIMEOUT", "45000")

      assert {:ok, config} = Config.load()
      assert config.timeout == 45_000

      System.delete_env("OPENBAO_ADDR")
      System.delete_env("OPENBAO_TOKEN")
      System.delete_env("OPENBAO_TIMEOUT")
    end
  end

  describe "secret_url/2" do
    setup do
      config = %Config{
        base_url: "https://vault.example.com",
        mount_path: "secret",
        version: :v2
      }

      {:ok, config: config}
    end

    test "builds v2 URL correctly", %{config: config} do
      url = Config.secret_url(config, "myapp/database/password")
      assert url == "https://vault.example.com/v1/secret/data/myapp/database/password"
    end

    test "builds v1 URL correctly", %{config: config} do
      v1_config = %{config | version: :v1}
      url = Config.secret_url(v1_config, "myapp/database/password")
      assert url == "https://vault.example.com/v1/secret/myapp/database/password"
    end

    test "handles custom mount path", %{config: config} do
      custom_config = %{config | mount_path: "kv"}
      url = Config.secret_url(custom_config, "secret-key")
      assert url == "https://vault.example.com/v1/kv/data/secret-key"
    end
  end

  describe "headers/1" do
    test "returns correct headers" do
      config = %Config{token: "test-token"}
      headers = Config.headers(config)

      assert {"X-Vault-Token", "test-token"} in headers
      assert {"Content-Type", "application/json"} in headers
    end
  end
end
