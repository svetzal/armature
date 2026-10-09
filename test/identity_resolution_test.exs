defmodule Armature.IdentityResolutionTest do
  use ExUnit.Case, async: false

  alias Armature.Registry.Checks
  alias Armature.Registry.CompiledCalls
  alias Armature.Registry.Node
  alias Armature.Registry.TestTracer

  test "declared uses compare lexical module identities for same-named components" do
    calls = CompiledCalls.calls(Example.Compositions)

    nodes = [
      node(:first, Example.First, :text),
      node(:second, Example.Second, :text),
      node(:aliased, Example.Compositions, :aliased, [:first]),
      node(:renamed, Example.Compositions, :renamed, [:first]),
      node(:imported, Example.Compositions, :imported, [:first]),
      node(:scoped, Example.Compositions, :scoped, [:first]),
      node(:outside, Example.Compositions, :outside, [:first]),
      node(:unknown, Example.Compositions, :unknown)
    ]

    errors = Checks.markup_uses(snapshot(nodes))
    assert {:markup_mismatch, :scoped, [:first], [:second]} in errors
    assert {:markup_mismatch, :renamed, [:first], [:second]} in errors
    assert {:markup_mismatch, :imported, [:first], [:second]} in errors
    assert length(errors) == 4
    assert calls["outside"] == [{Example.First, :text}]
    assert calls["unknown"] == [{Example.Compositions, :missing}]
  end

  test "test inventory requires the exact lexical module identity of same-named components" do
    nodes = [node(:first, Example.First, :text), node(:second, Example.Second, :text)]

    for file <- [
          "first",
          "alias",
          "renamed",
          "imported",
          "imported_call",
          "remote_call",
          "markup",
          "scoped"
        ] do
      inventory = TestTracer.inventory("test/support/inventory/#{file}.exs")

      assert Checks.exercised(%{nodes: nodes, test_source: inventory}) ==
               [{:untested_component, :second}]
    end

    assert Checks.exercised(%{nodes: nodes, test_source: MapSet.new()}) ==
             [{:untested_component, :first}, {:untested_component, :second}]
  end

  test "resolution preserves declaration order, nested modules and block scopes" do
    calls = CompiledCalls.calls(Example.Outer)
    assert calls["before"] == [{Example.First, :text}]
    assert calls["after_alias"] == [{Example.First, :text}, {Example.Second, :text}]
    assert calls["local_import"] == [{Example.Second, :text}]
    assert calls["after_function"] == [{Example.First, :text}]
    assert calls["branches"] == [{Example.First, :text}, {Example.Second, :text}]
    assert calls["after_nested"] == [{Example.Second, :text}]
    nested = CompiledCalls.calls(Example.Outer.Inner)
    assert nested["inherited"] == [{Example.Second, :text}]
    assert nested["changed"] == [{Example.First, :text}]
  end

  test "unresolved markup cannot satisfy even a uniquely named registry component" do
    nodes = [
      node(:first, Example.First, :text),
      node(:item, Example.Guarded, :item, [:first])
    ]

    assert Checks.markup_uses(snapshot(nodes)) == [
             {:markup_mismatch, :item, [:first],
              [
                {:unresolved_call, {Example.First, :mark}},
                {:unresolved_call, {Example.Guarded, :text}}
              ]}
           ]
  end

  test "test markup and captures share import exclusions and nested alias scopes" do
    nodes = [node(:first, Example.First, :text), node(:second, Example.Second, :text)]
    inventory = TestTracer.inventory("test/support/inventory/second.exs")

    assert Checks.exercised(%{nodes: nodes, test_source: inventory}) ==
             [{:untested_component, :first}]
  end

  test "function-local declarations cannot exercise a call outside that function" do
    nodes = [node(:first, Example.First, :text), node(:second, Example.Second, :text)]
    inventory = TestTracer.inventory("test/support/inventory/local_scope.exs")

    assert Checks.exercised(%{nodes: nodes, test_source: inventory}) ==
             [{:untested_component, :first}, {:untested_component, :second}]
  end

  test "module definitions and repeated imports do not invent aliases or exports" do
    calls = CompiledCalls.calls(Example.RepeatedImports)
    assert calls["item"] == [{Example.First, :text}, {First, :text}]
    assert calls["imported"] == [{Example.First, :text}, {Example.RepeatedImports, :mark}]
  end

  test "test source files have independent lexical scopes" do
    nodes = [node(:first, Example.First, :text), node(:second, Example.Second, :text)]
    inventory = TestTracer.inventory("test/support/inventory/independent.exs")

    assert Checks.exercised(%{nodes: nodes, test_source: inventory}) ==
             [{:untested_component, :first}, {:untested_component, :second}]
  end

  test "nested self aliases and __MODULE__ cannot credit a top-level namesake" do
    nodes = [
      node(:top, Inner, :text),
      node(:nested, Example.Outer.Inner, :text),
      node(:item, Example.Outer.Inner, :self_alias, [:top]),
      node(:self, Example.Outer.Inner, :self_module, [:nested])
    ]

    assert Checks.markup_uses(snapshot(nodes)) ==
             [{:markup_mismatch, :item, [:top], [:nested]}]

    inventory = TestTracer.inventory("test/support/inventory/nested.exs")

    assert Checks.exercised(%{
             nodes: [
               node(:top, Inner, :text),
               node(:nested, Example.Inventory.Outer.Inner, :text)
             ],
             test_source: inventory
           }) == [{:untested_component, :top}]
  end

  test "required aliases resolve to the required module in both checks" do
    assert CompiledCalls.calls(Example.Required)["item"] == [{Example.Second, :text}]
    inventory = TestTracer.inventory("test/support/inventory/required.exs")

    assert Checks.exercised(%{
             nodes: [node(:first, Example.First, :text), node(:second, Example.Second, :text)],
             test_source: inventory
           }) == [{:untested_component, :first}]
  end

  test "missing debug info fails clearly rather than guessing identities" do
    assert_raise ArgumentError, ~r/debug info is required for Example.WithoutDebugInfo/, fn ->
      CompiledCalls.calls(Example.WithoutDebugInfo)
    end
  end

  test "compiler rejects ambiguous imports and missing local components without inventing identities" do
    for file <- ["ambiguous", "missing"] do
      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert_raise CompileError, fn ->
            Code.compile_file("test/support/invalid/#{file}.exs")
          end
        end)

      assert output =~ "text/1"
      assert TestTracer.inventory("test/support/invalid/#{file}.exs") == MapSet.new()
    end
  end

  test "synchronous inventory sees captures from all separately compiled test files" do
    nodes = [node(:first, Example.First, :text), node(:second, Example.Second, :text)]
    inventory = TestTracer.inventory("test/inventory_*_test.exs")
    assert Checks.exercised(%{nodes: nodes, test_source: inventory}) == []
  end

  defp snapshot(nodes) do
    %{
      nodes: nodes,
      calls: Map.new(nodes, &{&1.module, CompiledCalls.calls(&1.module)})
    }
  end

  defp node(id, module, function, uses \\ []) do
    %Node{
      id: id,
      module: module,
      function: function,
      level: :molecule,
      purpose: "Demonstrates identity resolution.",
      uses: uses
    }
  end
end
