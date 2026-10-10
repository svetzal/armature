defmodule Armature.UI.RegistryTest do
  use Armature.RegistryCase,
    registry: Armature.UI.Registry,
    docs_path: "guides/components.md",
    test_source_glob: "test/components_test.exs"
end
