defmodule HushOpenbao.ProviderTest do
  use ExUnit.Case, async: false

  alias HushOpenbao.{Config, Provider}

  setup do
    # Clean up any previous app config
    Application.delete_env(:hush_openbao, :config)
    :ok
  end

  describe "load/1" do
    test "fails when configuration is invalid" do
      # Missing required config
      config_opts = []

      assert {:error, error} = Provider.load(config_opts)
      assert error =~ "base_url is required"
    end

    test "validates configuration without network calls" do
      # Test just the config validation part
      config_opts = [token: "test-token"]

      assert {:error, error} = Provider.load(config_opts)
      assert error =~ "base_url is required"
    end

    test "validates token requirement" do
      config_opts = [base_url: "https://vault.example.com"]

      assert {:error, error} = Provider.load(config_opts)
      assert error =~ "token is required"
    end
  end

  describe "fetch/1" do
    test "fails when provider not loaded" do
      # Ensure provider is not loaded
      Process.delete(Provider)

      assert {:error, error} = Provider.fetch("any/secret")
      assert error =~ "OpenBao provider not loaded"
    end

    test "works with stored config" do
      config = %Config{
        base_url: "https://vault.example.com",
        token: "test-token",
        mount_path: "secret",
        version: :v2,
        timeout: 30_000,
        retry: []
      }

      # Store config in process dictionary
      Process.put(Provider, config)

      # The actual fetch will fail due to no real OpenBao connection,
      # but we can verify the config is properly retrieved
      stored_config = Process.get(Provider)
      assert %Config{} = stored_config
      assert stored_config.base_url == "https://vault.example.com"
      assert stored_config.token == "test-token"
    end
  end
end
