defmodule Armature.RegistryCase do
  @moduledoc """
  Consumer ExUnit case template with one test per registry check.

      use Armature.RegistryCase, registry: Example.UI.Registry

  Supports `:extra_builtins`, `:docs_path`, and `:test_source_glob` (see
  `Armature.Registry.snapshot/2`). Optional tests are generated only when
  configured. Paths resolve relative to the test process's working directory.
  Component modules require debug info. When `:test_source_glob` is enabled,
  add `Armature.Registry.TestTracer.install()` to test/test_helper.exs. Registry
  tests with the inventory enabled must be synchronous so all test files have
  compiled before the inventory is read. `async: true` is rejected.
  Requires ExUnit in the consumer's test environment.
  """
  use ExUnit.CaseTemplate

  using options do
    registry = Keyword.fetch!(options, :registry)

    if options[:test_source_glob] && options[:async] do
      raise ArgumentError,
            "test inventory requires synchronous registry tests; remove async: true"
    end

    checks = [
      unique_ids: "registry ids are unique",
      valid_nodes: "registry nodes have valid levels, purposes and functions",
      known_uses: "registry uses name declared nodes",
      composition: "registry composition follows the level rules",
      public_components: "registry declares exactly the public components",
      markup_uses: "registry uses match markup calls"
    ]

    checks =
      if options[:docs_path],
        do: checks ++ [docs: "registry matches documentation tables"],
        else: checks

    checks =
      if options[:test_source_glob],
        do: checks ++ [exercised: "registry components appear in tests"],
        else: checks

    tests =
      for {check, description} <- checks do
        quote do
          test unquote(description), %{armature_registry: snapshot} do
            violations = apply(Armature.Registry.Checks, unquote(check), [snapshot])

            assert violations == [],
                   "#{unquote(description)}:\n#{inspect(violations, pretty: true)}"
          end
        end
      end

    quote do
      setup_all do
        %{armature_registry: Armature.Registry.snapshot(unquote(registry), unquote(options))}
      end

      unquote_splicing(tests)
    end
  end
end
