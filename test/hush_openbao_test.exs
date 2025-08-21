defmodule HushOpenbaoTest do
  use ExUnit.Case, async: true

  describe "module structure" do
    test "has documented public functions" do
      # Test that the main module has the expected structure
      assert HushOpenbao.__info__(:functions) |> Keyword.has_key?(:load)
      assert HushOpenbao.__info__(:functions) |> Keyword.has_key?(:fetch)
    end

    test "fetch/1 delegates to Provider.fetch/1" do
      # Test that the main module delegates correctly
      # This will fail because provider is not loaded, but proves delegation works
      assert {:error, error} = HushOpenbao.fetch("test/key")
      assert error =~ "not loaded"
    end
  end
end
