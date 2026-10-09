defmodule Armature.Registry.TestTracer do
  @moduledoc """
  Records compiler-resolved function/1 calls and captures for the optional test inventory.

  Install before test files compile, in `test/test_helper.exs`:

      Armature.Registry.TestTracer.install()

  Synchronous ExUnit tests run after `mix test` compiles all selected test
  files. Read the inventory only from synchronous tests; `Armature.RegistryCase`
  rejects `async: true` when the inventory is enabled. Only calls within
  successfully compiled modules in matching files count. This inventory
  does not prove that a test executes or asserts a component.
  """

  @doc "Installs the tracer for this test run, preserving other compiler tracers."
  def install do
    case Agent.start(fn -> %{pending: %{}, compiled: %{}} end, name: __MODULE__) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    tracers = Code.get_compiler_option(:tracers)
    Code.put_compiler_option(:tracers, Enum.uniq([__MODULE__ | tracers]))
  end

  @doc false
  def trace({kind, _, module, function, 1}, env)
      when kind in [:remote_function, :imported_function] and not is_nil(env.module) do
    key = {Path.expand(env.file), env.module}

    Agent.update(__MODULE__, fn state ->
      pending =
        Map.update(state.pending, key, MapSet.new([{module, function}]), fn calls ->
          MapSet.put(calls, {module, function})
        end)

      %{state | pending: pending}
    end)
  end

  def trace({:on_module, _, _}, env) do
    key = {Path.expand(env.file), env.module}

    Agent.update(__MODULE__, fn state ->
      {calls, pending} = Map.pop(state.pending, key, MapSet.new())
      %{state | pending: pending, compiled: Map.put(state.compiled, key, calls)}
    end)
  end

  def trace(_, _), do: :ok

  @doc false
  def inventory(glob) do
    if __MODULE__ not in Code.get_compiler_option(:tracers) or
         is_nil(Process.whereis(__MODULE__)) do
      raise ArgumentError,
            "test inventory requires the compilation tracer; add " <>
              "Armature.Registry.TestTracer.install() to test/test_helper.exs before tests compile"
    end

    files = glob |> Path.wildcard() |> Enum.map(&Path.expand/1)

    Agent.get(__MODULE__, fn state ->
      Enum.reduce(state.compiled, MapSet.new(), fn {{file, _module}, identities}, calls ->
        if file in files, do: MapSet.union(calls, identities), else: calls
      end)
    end)
  end
end
