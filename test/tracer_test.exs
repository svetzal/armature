defmodule Armature.TracerTest do
  use ExUnit.Case, async: false

  alias Armature.Registry
  alias Armature.Registry.TestTracer

  test "enabled inventory fails with the installation line when tracer is absent" do
    previous = Code.get_compiler_option(:tracers)
    Code.put_compiler_option(:tracers, List.delete(previous, TestTracer))

    try do
      assert_raise ArgumentError, ~r/Armature.Registry.TestTracer.install\(\)/, fn ->
        Registry.snapshot(Armature.Fixtures.Registry, test_source_glob: "test/**/*_test.exs")
      end
    after
      Code.put_compiler_option(:tracers, previous)
    end
  end

  test "installation is idempotent and preserves other tracers" do
    previous = Code.get_compiler_option(:tracers)
    TestTracer.install()
    TestTracer.install()
    assert Code.get_compiler_option(:tracers) == previous
  end

  test "inventory registry cases reject asynchronous execution" do
    assert_raise ArgumentError, ~r/remove async: true/, fn ->
      require Armature.RegistryCase

      quoted =
        quote do
          Armature.RegistryCase.__using__(
            registry: Armature.Fixtures.Registry,
            async: true,
            test_source_glob: "test/**/*_test.exs"
          )
        end

      Macro.expand_once(quoted, __ENV__)
    end
  end
end
