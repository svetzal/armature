defmodule Armature.Registry do
  @moduledoc """
  A consumer implements `nodes/0` and `modules/0` to declare its library as data.

  Tokens are CSS custom properties, not registry nodes. `snapshot/2` reads
  compiled metadata and resolved calls once. Pass that immutable snapshot to
  `Armature.Registry.Checks` for pure validation. Component modules require
  BEAM debug info (enabled by default in dev and test); component source files are not read.
  """
  alias Armature.Registry.CompiledCalls
  alias Armature.Registry.Node

  @type level :: :atom | :layout | :molecule | :organism | :template
  @callback nodes() :: [Node.t()]
  @callback modules() :: [module()]

  @doc "Registry levels, lowest first."
  @spec levels() :: [level()]
  def levels, do: [:atom, :layout, :molecule, :organism, :template]

  @doc "Returns the registry's nodes at a level, preserving declaration order."
  @spec at_level(module(), level()) :: [Node.t()]
  def at_level(registry, level), do: Enum.filter(registry.nodes(), &(&1.level == level))

  @doc """
  Captures a registry's compiled calls and optional documentation/test inventory.

  Options are `:extra_builtins` (names as strings), `:docs_path`, and
  `:test_source_glob`. Missing files or modules raise with their original error;
  optional checks are disabled when their option is absent. The test inventory
  requires `Armature.Registry.TestTracer.install/0` in test_helper.exs and must
  be captured from a synchronous test, after all selected test files compile.
  `:extra_builtins` remains supported for external components to exclude.
  """
  @spec snapshot(module(), keyword()) :: map()
  def snapshot(registry, options \\ []) do
    nodes = registry.nodes()
    modules = registry.modules()
    inspected_modules = Enum.uniq(modules ++ Enum.map(nodes, & &1.module))

    metadata = Map.new(inspected_modules, &{&1, metadata(&1)})

    calls = Map.new(inspected_modules, &{&1, CompiledCalls.calls(&1, options)})

    %{
      nodes: nodes,
      modules: modules,
      metadata: metadata,
      calls: calls,
      docs: read_optional(options[:docs_path]),
      test_source: test_inventory(options[:test_source_glob])
    }
  end

  defp metadata(module) do
    Code.ensure_loaded!(module)

    components =
      if function_exported?(module, :__components__, 0),
        do: Map.keys(module.__components__()),
        else: []

    %{exports: module.__info__(:functions), components: components}
  end

  defp read_optional(nil), do: nil
  defp read_optional(path), do: File.read!(path)

  defp test_inventory(nil), do: nil

  defp test_inventory(glob), do: Armature.Registry.TestTracer.inventory(glob)
end
