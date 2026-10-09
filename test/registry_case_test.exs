defmodule Armature.ConsumerCaseTest do
  use Armature.RegistryCase, registry: Armature.Fixtures.Registry
end

defmodule Armature.ConsumerOptionsCaseTest do
  use Armature.RegistryCase,
    registry: Armature.Fixtures.Registry,
    extra_builtins: ["example_builtin"],
    docs_path: "test/support/components.md",
    test_source_glob: "test/registry_case_test.exs"

  import Phoenix.LiveViewTest
  alias Armature.Fixtures.Compositions
  alias Armature.Fixtures.Elements

  test "consumer renders every registered component" do
    for component <- [
          &Elements.text/1,
          &Elements.mark/1,
          &Compositions.row/1,
          &Compositions.group/1,
          &Compositions.section/1,
          &Compositions.region/1,
          &Compositions.page/1
        ] do
      assert render_component(component, label: "Example")
             |> LazyHTML.from_fragment()
             |> LazyHTML.text() =~ "Example"
    end
  end
end

defmodule Armature.RegistryCaseContractTest do
  use ExUnit.Case, async: true

  test "consumer gets one test per check and optional tests only when configured" do
    basic = Armature.ConsumerCaseTest.__ex_unit__().tests
    optional = Armature.ConsumerOptionsCaseTest.__ex_unit__().tests
    assert length(basic) == 6
    assert length(optional) == 9
    refute Enum.any?(basic, &(&1.name == :"test registry matches documentation tables"))
    assert Enum.any?(optional, &(&1.name == :"test registry matches documentation tables"))
    assert Enum.any?(optional, &(&1.name == :"test registry components appear in tests"))
  end

  test "consumer failures name the check and include the specific violation" do
    snapshot = Armature.Registry.snapshot(Armature.Fixtures.Registry)
    [node | _] = snapshot.nodes
    snapshot = %{snapshot | nodes: [node | snapshot.nodes]}

    error =
      assert_raise ExUnit.AssertionError, fn ->
        Armature.ConsumerCaseTest."test registry ids are unique"(%{armature_registry: snapshot})
      end

    assert error.message =~ "registry ids are unique"
    assert error.message =~ "{:duplicate_id, :text, 2}"
  end
end
