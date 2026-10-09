defmodule Armature.Registry.Checks do
  @moduledoc """
  Pure checks over the map returned by `Armature.Registry.snapshot/2`.

  Each function returns a list of tagged violation tuples, empty when clean.
  Optional checks return an empty list when their input is `nil`. Ids identify
  nodes; code identities are `{module, function}` pairs. Results preserve node
  order except set differences, which are sorted for stable diagnostics.
  """
  alias Armature.Registry

  @doc "Reports duplicate node ids."
  def unique_ids(%{nodes: nodes}) do
    nodes
    |> Enum.frequencies_by(& &1.id)
    |> Enum.filter(fn {_, count} -> count > 1 end)
    |> Enum.sort()
    |> Enum.map(fn {id, count} -> {:duplicate_id, id, count} end)
  end

  @doc "Checks known levels, nonblank purposes and exported function/1 declarations."
  def valid_nodes(%{nodes: nodes, metadata: metadata}) do
    Enum.flat_map(nodes, fn node ->
      errors =
        if node.level in Registry.levels(), do: [], else: [{:unknown_level, node.id, node.level}]

      errors =
        if purpose?(node.purpose), do: errors, else: errors ++ [{:missing_purpose, node.id}]

      if {node.function, 1} in metadata[node.module].exports,
        do: errors,
        else: errors ++ [{:missing_function, node.id, node.module, node.function}]
    end)
  end

  @doc "Reports dependencies whose ids are absent from the registry."
  def known_uses(%{nodes: nodes}) do
    ids = MapSet.new(nodes, & &1.id)
    for node <- nodes, use <- node.uses, use not in ids, do: {:unknown_use, node.id, use}
  end

  @doc "Checks strictly downward composition, allowing distinct peer organisms."
  def composition(%{nodes: nodes}) do
    by_id = Map.new(nodes, &{&1.id, &1})

    for node <- nodes,
        use <- node.uses,
        used = by_id[use],
        node.level in Registry.levels(),
        used.level in Registry.levels(),
        not allowed?(node, used),
        do: {:invalid_composition, node.id, node.level, use, used.level}
  end

  @doc "Checks exact correspondence with public Phoenix component metadata in library modules."
  def public_components(%{nodes: nodes, modules: modules, metadata: metadata}) do
    declared = MapSet.new(nodes, &{&1.module, &1.function})

    defined =
      for module <- modules,
          function <- metadata[module].components,
          {function, 1} in metadata[module].exports,
          into: MapSet.new(),
          do: {module, function}

    difference(defined, declared, :undeclared_component) ++
      difference(declared, defined, :not_public_component)
  end

  @doc "Checks declared uses against compiler-resolved component captures, including private helpers."
  def markup_uses(%{nodes: nodes, calls: calls}) do
    Enum.flat_map(nodes, fn node ->
      found =
        calls[node.module]
        |> Map.get(Atom.to_string(node.function), [])
        |> Enum.map(&resolve_call(&1, nodes))
        |> Enum.uniq()
        |> Enum.sort()

      declared = Enum.sort(Enum.uniq(node.uses))
      if found == declared, do: [], else: [{:markup_mismatch, node.id, declared, found}]
    end)
  end

  @doc """
  Checks Markdown tables under `## Atoms`, `## Layouts`, `## Molecules`,
  `## Organisms`, and `## Templates`. First-column backticks name registry ids;
  an optional second column lists backticked use ids or `—` for no uses.
  A prose second column is treated as a purpose column, not a uses declaration.
  """
  def docs(%{docs: nil}), do: []

  def docs(%{docs: source, nodes: nodes}) do
    documented = documented_nodes(source)
    expected = Enum.map(nodes, &{&1.level, Atom.to_string(&1.id)}) |> Enum.sort()
    listed = Enum.map(documented, fn {level, id, _} -> {level, id} end) |> Enum.sort()
    errors = if expected == listed, do: [], else: [{:docs_mismatch, expected, listed}]

    errors ++
      for {level, id, uses} <- documented,
          is_list(uses),
          node = Enum.find(nodes, &(&1.level == level and Atom.to_string(&1.id) == id)),
          expected_uses = Enum.map(node.uses, &Atom.to_string/1) |> Enum.sort(),
          Enum.sort(uses) != expected_uses,
          do: {:docs_uses_mismatch, node.id, expected_uses, Enum.sort(uses)}
  end

  @doc """
  Checks compiler-resolved function/1 calls and captures recorded by
  `Armature.Registry.TestTracer` in the configured test files. This inventory
  does not prove that a test executes or asserts the component.
  """
  def exercised(%{test_source: nil}), do: []

  def exercised(%{test_source: identities, nodes: nodes}) do
    for node <- nodes,
        {node.module, node.function} not in identities,
        do: {:untested_component, node.id}
  end

  defp purpose?(purpose) when is_binary(purpose), do: String.trim(purpose) != ""
  defp purpose?(_), do: false

  defp allowed?(%{id: id}, %{id: id}), do: false
  defp allowed?(%{level: :organism}, %{level: :organism}), do: true

  defp allowed?(node, used),
    do:
      Enum.find_index(Registry.levels(), &(&1 == used.level)) <
        Enum.find_index(Registry.levels(), &(&1 == node.level))

  defp difference(left, right, tag) do
    left
    |> MapSet.difference(right)
    |> Enum.sort()
    |> Enum.map(fn {module, function} -> {tag, module, function} end)
  end

  defp resolve_call({module, function} = call, nodes) do
    matches = Enum.filter(nodes, &(&1.module == module and &1.function == function))
    resolve_matches(matches, call)
  end

  defp resolve_matches([node], _call), do: node.id
  defp resolve_matches(_, call), do: {:unresolved_call, call}

  defp documented_nodes(source) do
    source
    |> String.split(~r/^## /m)
    |> Enum.flat_map(fn section ->
      [heading | lines] = String.split(section, "\n")

      level =
        Enum.find(
          Registry.levels(),
          &(String.capitalize(Atom.to_string(&1)) <> "s" == String.trim(heading))
        )

      if level, do: table_rows(lines, level), else: []
    end)
  end

  defp table_rows(lines, level) do
    for line <- lines,
        String.starts_with?(String.trim(line), "| `"),
        [names | remaining] = line |> String.split("|", trim: true) |> Enum.map(&String.trim/1),
        id <- backticked(names),
        do: {level, id, cell_uses(List.first(remaining))}
  end

  defp cell_uses("—"), do: []
  defp cell_uses(nil), do: nil

  defp cell_uses(cell) do
    if Regex.match?(~r/^`[\w]+`(?:,\s*`[\w]+`)*$/, cell), do: backticked(cell), else: nil
  end

  defp backticked(cell) do
    for [name] <- Regex.scan(~r/`([\w]+)`/, cell, capture: :all_but_first), do: name
  end
end
