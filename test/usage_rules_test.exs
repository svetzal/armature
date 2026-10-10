defmodule Armature.UsageRulesTest do
  # usage-rules.md is read by agents in consuming applications. Every name it
  # gives them must exist, or they will build against an API that is not there.
  use ExUnit.Case, async: true

  @rules File.read!(Path.expand("../usage-rules.md", __DIR__))

  # Backticked words that are values or HTML and CSS terms rather than
  # component, attribute or slot names.
  @values ~w(select textarea checkbox compact attr slot outline script head)

  test "the rules file ships in the Hex package" do
    files = Mix.Project.config()[:package][:files]
    assert "usage-rules.md" in files
  end

  test "every Armature module named in the rules exists" do
    for [module] <- Regex.scan(~r/\bArmature(?:\.[A-Z]\w*)+/, @rules) |> Enum.uniq() do
      loaded =
        try do
          Code.ensure_loaded?(Module.safe_concat([module]))
        rescue
          ArgumentError -> false
        end

      assert loaded, "#{module} does not exist"
    end
  end

  test "every function named in the rules is exported" do
    for {module, function, arity} <- [
          {Armature.Tokens.Values, :check!, 1},
          {Armature.UI.Registry, :nodes, 0},
          {Armature.UI.Registry, :modules, 0},
          {Armature.Catalogue.BaselineExamples, :examples, 1},
          {Armature.Catalogue.BaselineExamples, :init, 0},
          {Armature.Catalogue.BaselineExamples, :handle_event, 3}
        ] do
      Code.ensure_loaded!(module)

      assert function_exported?(module, function, arity),
             "#{inspect(module)}.#{function}/#{arity}"
    end

    Code.ensure_loaded!(Armature.Catalogue.Router)
    assert macro_exported?(Armature.Catalogue.Router, :armature_catalogue, 2)

    callbacks = Armature.Registry.behaviour_info(:callbacks)
    assert {:nodes, 0} in callbacks and {:modules, 0} in callbacks

    example_callbacks = Armature.Catalogue.Examples.behaviour_info(:callbacks)

    for callback <- [examples: 1, init: 0, handle_event: 3],
        do: assert(callback in example_callbacks)
  end

  test "every backticked component, attribute or slot name exists" do
    components = Armature.Components.__components__()

    known =
      components
      |> Enum.flat_map(fn {name, spec} ->
        slot_attrs = Enum.flat_map(spec.slots, fn slot -> Enum.map(slot.attrs, & &1.name) end)
        [name | Enum.map(spec.attrs, & &1.name) ++ Enum.map(spec.slots, & &1.name) ++ slot_attrs]
      end)
      |> Kernel.++(
        Map.keys(%Armature.Registry.Node{
          id: :x,
          level: :atom,
          module: X,
          function: :x,
          purpose: ""
        })
      )
      |> Enum.map(&Atom.to_string/1)
      |> MapSet.new()

    names =
      ~r/`([a-z][a-z0-9_]*)(?:="[^"]*"|=\{[^}]*\})?`/
      |> Regex.scan(@rules)
      |> Enum.map(fn [_, name | _] -> name end)
      |> Enum.uniq()

    unknown = Enum.reject(names, &(&1 in known or &1 in @values))

    assert unknown == [],
           "names in usage-rules.md with no matching component, attr or slot: #{inspect(unknown)}"
  end

  test "node fields named in the rules exist on the struct" do
    fields = %Armature.Registry.Node{id: :x, level: :atom, module: X, function: :x, purpose: ""}

    for field <- ~w(id level module function purpose uses)a do
      assert Map.has_key?(fields, field)
    end
  end
end
