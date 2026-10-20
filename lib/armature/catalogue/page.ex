defmodule Armature.Catalogue.Page do
  @moduledoc false

  alias Armature.Registry.Node

  @type t :: %{
          node: Node.t() | nil,
          level: Armature.Registry.level() | nil,
          tokens?: boolean(),
          heading: String.t(),
          heading_id: String.t(),
          eyebrow: String.t(),
          uses: [Node.t()],
          used_by: [Node.t()]
        }

  @spec resolve([Node.t()], map()) :: t()
  def resolve(nodes, params) do
    tokens? = params["section"] == "tokens"
    node = chosen_node(nodes, params)
    level = if node, do: node.level, else: chosen_level(params)
    {heading, heading_key, section} = titles(tokens?, node, level)

    %{
      node: node,
      level: level,
      tokens?: tokens?,
      heading: heading,
      heading_id: "armature-catalogue-heading-#{heading_key}",
      eyebrow: "Library / " <> section,
      uses: uses(nodes, node),
      used_by: used_by(nodes, node)
    }
  end

  @spec usage(Node.t()) :: String.t()
  def usage(node) do
    with {:docs_v1, _, _, _, _, _, docs} <- Code.fetch_docs(node.module),
         {_, _, _, %{"en" => text}, _} <-
           Enum.find(docs, fn {identity, _, _, _, _} ->
             identity == {:function, node.function, 1}
           end) do
      text
    else
      _ -> "No usage documentation available."
    end
  end

  @spec level_name(Armature.Registry.level()) :: String.t()
  def level_name(level), do: level |> to_string() |> String.capitalize() |> Kernel.<>("s")

  @spec node_path(String.t(), Node.t()) :: String.t()
  def node_path(path, node), do: path <> "?" <> URI.encode_query(%{"node" => node.id})

  defp chosen_node(nodes, params) do
    Enum.find(nodes, &(to_string(&1.id) == params["node"])) ||
      case chosen_level(params) do
        nil -> nil
        level -> Enum.find(nodes, &(&1.level == level))
      end
  end

  defp chosen_level(params),
    do: Enum.find(Armature.Registry.levels(), &(to_string(&1) == params["level"]))

  defp titles(true, _node, _level), do: {"Tokens", "tokens", "Tokens"}
  defp titles(false, nil, nil), do: {"Component catalogue", "index", "Catalogue"}
  defp titles(false, nil, level), do: {"Component catalogue", "index", level_name(level)}
  defp titles(false, node, level), do: {to_string(node.id), node.id, level_name(level)}

  defp uses(_nodes, nil), do: []
  defp uses(nodes, node), do: Enum.filter(nodes, &(&1.id in node.uses))

  defp used_by(_nodes, nil), do: []
  defp used_by(nodes, node), do: Enum.filter(nodes, &(node.id in &1.uses))
end
