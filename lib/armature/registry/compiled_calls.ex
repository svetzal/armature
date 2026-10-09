defmodule Armature.Registry.CompiledCalls do
  @moduledoc false

  def calls(module, options \\ []) do
    definitions = definitions!(module)
    by_name = Map.new(definitions, fn {name, kind, _, clauses} -> {name, {kind, clauses}} end)

    definitions
    |> Enum.filter(fn {{_, arity}, _, _, _} -> arity == 1 end)
    |> Map.new(fn {{function, 1} = name, _, _, _} ->
      calls = collect(name, module, by_name, MapSet.new())

      calls =
        calls
        |> Enum.reject(fn {target, function} ->
          target == Phoenix.Component or
            Atom.to_string(function) in Keyword.get(options, :extra_builtins, [])
        end)
        |> Enum.uniq()
        |> Enum.sort()

      {Atom.to_string(function), calls}
    end)
  end

  defp definitions!(module) do
    with {^module, binary, _} <- :code.get_object_code(module),
         {:ok, {^module, [debug_info: {:debug_info_v1, backend, data}]}} <-
           :beam_lib.chunks(binary, [:debug_info]),
         {:ok, %{definitions: definitions}} <- backend.debug_info(:elixir_v1, module, data, []) do
      definitions
    else
      _ ->
        raise ArgumentError,
              "debug info is required for #{inspect(module)} registry checks; " <>
                "enable debug_info (on by default in dev and test) and recompile"
    end
  end

  defp collect(name, module, definitions, visited) do
    if MapSet.member?(visited, name) do
      []
    else
      visited = MapSet.put(visited, name)
      {_, clauses} = Map.fetch!(definitions, name)

      {_, calls} =
        Macro.prewalk(Enum.map(clauses, fn {_, _, _, body} -> body end), [], fn
          {:&, _, [{:/, _, [{{:., _, [target, function]}, _, []}, 1]}]} = ast, calls
          when is_atom(target) and is_atom(function) ->
            {ast, [{target, function} | calls]}

          {:&, _, [{:/, _, [{function, _, context}, 1]}]} = ast, calls
          when is_atom(function) and is_atom(context) ->
            {ast, local_calls({function, 1}, module, definitions, visited) ++ calls}

          {:super, metadata, arguments} = ast, calls ->
            {_, function} = Keyword.fetch!(metadata, :super)
            name = {function, length(arguments)}
            {ast, collect(name, module, definitions, visited) ++ calls}

          ast, calls ->
            {ast, calls}
        end)

      calls
    end
  end

  defp local_calls({function, 1} = name, module, definitions, visited) do
    case Map.get(definitions, name) do
      {:defp, _} -> collect(name, module, definitions, visited)
      _ -> [{module, function}]
    end
  end
end
