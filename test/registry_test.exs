defmodule Armature.RegistryTest do
  use ExUnit.Case, async: false
  alias Armature.Fixtures.Compositions
  alias Armature.Fixtures.Elements
  alias Armature.Fixtures.Registry, as: Fixture
  alias Armature.Registry
  alias Armature.Registry.Checks
  alias Armature.Registry.CompiledCalls

  setup_all do
    %{snapshot: Registry.snapshot(Fixture)}
  end

  test "levels run from atom to template without tokens" do
    assert Registry.levels() == [:atom, :layout, :molecule, :organism, :template]
  end

  test "nodes are listed level by level in declaration order" do
    assert Enum.flat_map(Registry.levels(), &Registry.at_level(Fixture, &1)) == Fixture.nodes()
    assert Registry.at_level(Fixture, :layout) |> Enum.map(& &1.id) == [:row]
  end

  test "all structural checks pass for a clean consumer", %{snapshot: snapshot} do
    for check <- [
          :unique_ids,
          :valid_nodes,
          :known_uses,
          :composition,
          :public_components,
          :markup_uses
        ] do
      assert apply(Checks, check, [snapshot]) == [], "#{check} failed"
    end
  end

  test "duplicate ids include the duplicate count", %{snapshot: snapshot} do
    [node | _] = snapshot.nodes

    assert Checks.unique_ids(%{snapshot | nodes: [node | snapshot.nodes]}) == [
             {:duplicate_id, :text, 2}
           ]
  end

  test "unknown levels are reported", %{snapshot: snapshot} do
    assert Checks.valid_nodes(change(snapshot, :text, level: :unknown)) == [
             {:unknown_level, :text, :unknown}
           ]
  end

  test "missing purposes are reported", %{snapshot: snapshot} do
    for purpose <- ["  ", nil] do
      assert Checks.valid_nodes(change(snapshot, :text, purpose: purpose)) == [
               {:missing_purpose, :text}
             ]
    end
  end

  test "missing exported functions are reported", %{snapshot: snapshot} do
    assert Checks.valid_nodes(change(snapshot, :text, function: :absent)) == [
             {:missing_function, :text, Elements, :absent}
           ]
  end

  test "unknown use ids are reported", %{snapshot: snapshot} do
    assert Checks.known_uses(change(snapshot, :row, uses: [:absent])) == [
             {:unknown_use, :row, :absent}
           ]
  end

  test "uses that do not point to a lower level are rejected", %{snapshot: snapshot} do
    for {id, level, used, used_level} <- [
          {:text, :atom, :row, :layout},
          {:row, :layout, :group, :molecule},
          {:group, :molecule, :page, :template},
          {:page, :template, :page, :template},
          {:text, :atom, :mark, :atom}
        ] do
      assert Checks.composition(change(snapshot, id, uses: [used])) == [
               {:invalid_composition, id, level, used, used_level}
             ]
    end
  end

  test "organisms can use peers but cannot use themselves", %{snapshot: snapshot} do
    assert Checks.composition(snapshot) == []

    assert Checks.composition(change(snapshot, :section, uses: [:section])) == [
             {:invalid_composition, :section, :organism, :section, :organism}
           ]
  end

  test "composition tolerates invalid nodes so other checks can report them", %{
    snapshot: snapshot
  } do
    assert Checks.composition(change(snapshot, :row, uses: [:absent])) == []
    assert Checks.composition(change(snapshot, :row, level: :unknown)) == []
  end

  test "public components missing from declarations are reported", %{snapshot: snapshot} do
    snapshot = %{snapshot | nodes: Enum.reject(snapshot.nodes, &(&1.id == :text))}
    assert Checks.public_components(snapshot) == [{:undeclared_component, Elements, :text}]
  end

  test "ordinary exports cannot be declared", %{snapshot: snapshot} do
    assert Checks.public_components(declare_extra(snapshot, Elements, :ordinary)) == [
             {:not_public_component, Elements, :ordinary}
           ]
  end

  test "private components cannot be declared", %{snapshot: snapshot} do
    assert Checks.public_components(declare_extra(snapshot, Compositions, :helper)) == [
             {:not_public_component, Compositions, :helper}
           ]
  end

  test "components in modules outside the declared library are rejected", %{snapshot: snapshot} do
    snapshot = %{snapshot | modules: [Compositions]}

    assert Checks.public_components(snapshot) == [
             {:not_public_component, Elements, :mark},
             {:not_public_component, Elements, :text}
           ]
  end

  test "markup differences include dependencies through private helpers", %{snapshot: snapshot} do
    assert Checks.markup_uses(change(snapshot, :group, uses: [:row])) == [
             {:markup_mismatch, :group, [:row], [:mark, :row]}
           ]

    assert Checks.markup_uses(change(snapshot, :row, uses: [])) == [
             {:markup_mismatch, :row, [], [:text]}
           ]
  end

  test "unknown markup calls remain visible instead of being dropped", %{snapshot: snapshot} do
    calls = Map.put(snapshot.calls, Elements, %{"text" => [{Unknown, :widget}]})

    assert Checks.markup_uses(%{snapshot | calls: calls}) == [
             {:markup_mismatch, :text, [], [{:unresolved_call, {Unknown, :widget}}]}
           ]
  end

  test "optional checks are disabled by default", %{snapshot: snapshot} do
    assert Checks.docs(snapshot) == []
    assert Checks.exercised(snapshot) == []
  end

  test "matching documentation tables pass", %{snapshot: snapshot} do
    assert Checks.docs(%{snapshot | docs: docs(snapshot.nodes)}) == []
  end

  test "a documented dependency mismatch is reported", %{snapshot: snapshot} do
    assert Checks.docs(%{
             snapshot
             | docs: docs(snapshot.nodes) |> String.replace("`mark`, `row`", "`row`")
           }) == [{:docs_uses_mismatch, :group, ["mark", "row"], ["row"]}]
  end

  test "a documentation mismatch lists the expected rows beside the documented rows", %{
    snapshot: snapshot
  } do
    expected = Enum.map(snapshot.nodes, &{&1.level, Atom.to_string(&1.id)}) |> Enum.sort()

    assert Checks.docs(%{snapshot | docs: "## Atoms\n| `extra` | — |\n"}) == [
             {:docs_mismatch, expected, [atom: "extra"]}
           ]
  end

  test "documentation rows may carry a purpose column", %{snapshot: snapshot} do
    source =
      String.replace(docs(snapshot.nodes), "| `text` | — |", "| `text` | Plain text purpose |")

    assert Checks.docs(%{snapshot | docs: source}) == []
  end

  test "repeated documentation rows are reported", %{snapshot: snapshot} do
    source = docs(snapshot.nodes) <> "\n## Atoms\n| `text` | — |"
    assert [{:docs_mismatch, _, _}] = Checks.docs(%{snapshot | docs: source})
  end

  test "test inventory accepts every exercised component", %{snapshot: snapshot} do
    identities = MapSet.new(snapshot.nodes, &{&1.module, &1.function})
    assert Checks.exercised(%{snapshot | test_source: identities}) == []
  end

  test "test inventory reports components no test exercises", %{snapshot: snapshot} do
    identities = MapSet.new(snapshot.nodes, &{&1.module, &1.function})

    assert Checks.exercised(%{
             snapshot
             | test_source: MapSet.delete(identities, {Elements, :mark})
           }) == [{:untested_component, :mark}]
  end

  test "snapshot reads optional documentation from its path" do
    snapshot = Registry.snapshot(Fixture, docs_path: "test/support/components.md")
    assert Checks.docs(snapshot) == []
  end

  test "snapshot reads the test inventory from its glob" do
    snapshot = Registry.snapshot(Fixture, test_source_glob: "test/registry_case_test.exs")
    assert Checks.exercised(snapshot) == []
  end

  test "a test glob without matches leaves every component untested" do
    assert Checks.exercised(
             Registry.snapshot(Fixture, test_source_glob: "test/support/no_matches_*.exs")
           )
           |> length() == 7
  end

  test "markup collects calls through cyclic private helpers across clauses" do
    calls = CompiledCalls.calls(Example.PrivateHelpers, extra_builtins: ["custom_builtin"])
    assert calls["local"] == []

    assert calls["item"] == [
             {Example.First, :mark},
             {Example.First, :text},
             {Example.PrivateHelpers, :local},
             {Example.Required, :item},
             {Example.Second, :text}
           ]
  end

  test "markup reads calls from a guarded clause" do
    assert {Example.First, :mark} in CompiledCalls.calls(Example.Guarded)["item"]
  end

  test "an excluded import resolves to the local component" do
    calls = CompiledCalls.calls(Example.Guarded)["item"]
    assert {Example.Guarded, :text} in calls
    refute {Example.First, :text} in calls
  end

  test "reading calls from a missing module raises" do
    assert_raise ArgumentError, fn -> CompiledCalls.calls(Example.Absent) end
  end

  test "an imported library component overrides a builtin name" do
    assert {Example.External, :link} in CompiledCalls.calls(Example.BuiltinNames)["item"]
  end

  test "qualified framework calls are not recorded" do
    calls = CompiledCalls.calls(Example.BuiltinNames)["item"]
    refute Enum.any?(calls, fn {module, _function} -> module == Phoenix.Component end)
  end

  test "unqualified calls without lexical evidence remain unresolved", %{
    snapshot: snapshot
  } do
    calls =
      Map.put(
        snapshot.calls,
        Compositions,
        Map.put(snapshot.calls[Compositions], "row", [{nil, :text}])
      )

    assert Checks.markup_uses(%{snapshot | calls: calls}) == [
             {:markup_mismatch, :row, [:text], [{:unresolved_call, {nil, :text}}]}
           ]

    [node | _] = snapshot.nodes

    ambiguous = %{
      snapshot
      | calls: calls,
        nodes: snapshot.nodes ++ [%{node | id: :other_text, module: Compositions}]
    }

    assert {:markup_mismatch, :row, [:text], [{:unresolved_call, {nil, :text}}]} in Checks.markup_uses(
             ambiguous
           )
  end

  defp change(snapshot, id, attributes) do
    %{
      snapshot
      | nodes:
          Enum.map(snapshot.nodes, fn node ->
            if node.id == id, do: struct!(node, attributes), else: node
          end)
    }
  end

  defp declare_extra(snapshot, module, function) do
    [node | _] = snapshot.nodes
    extra = %{node | id: :extra, module: module, function: function}
    %{snapshot | nodes: snapshot.nodes ++ [extra]}
  end

  defp docs(nodes) do
    Enum.map_join(Registry.levels(), "\n", fn level ->
      rows =
        for node <- nodes, node.level == level do
          uses =
            if node.uses == [],
              do: "—",
              else: node.uses |> Enum.sort() |> Enum.map_join(", ", &"`#{&1}`")

          "| `#{node.id}` | #{uses} |"
        end

      "## #{String.capitalize(Atom.to_string(level))}s\n" <> Enum.join(rows, "\n")
    end)
  end
end
