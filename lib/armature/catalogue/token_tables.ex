defmodule Armature.Catalogue.TokenTables do
  @moduledoc false
  # The token page's computed tables: every token's resolved value and every
  # required contrast pair, per context. They change with the configured values
  # and the contrast calculation, not with the token demonstrations.
  use Phoenix.Component
  alias Armature.Components.Organisms

  attr(:tokens, :list, required: true)
  attr(:values, :map, required: true)

  def reference(assigns) do
    ~H"""
    <Organisms.panel id="catalogue-token-reference" heading="Token reference">
      <p>
        Every contract token, its role and its resolved value in each context. Scroll across for all six contexts.
      </p>
      <Organisms.data_table
        id="catalogue-token-reference-table"
        rows={@tokens}
        row_id={&String.trim_leading(&1.name, "--")}
        density="compact"
        caption="Complete token contract and context values"
      >
        <:col :let={token} label="Token"><code>{token.name}</code></:col>
        <:col :let={token} label="Group">{token.group}</:col>
        <:col :let={token} label="Role">{token.role}</:col>
        <:col :let={token} :for={context <- themes()} label={theme_name(context)}>
          {Map.fetch!(@values[context].values, token.name)}
        </:col>
      </Organisms.data_table>
    </Organisms.panel>
    """
  end

  attr(:values, :map, required: true)

  def contrast(assigns) do
    ~H"""
    <Organisms.panel id="catalogue-token-contrast" heading="Contrast">
      <p>
        Every required foreground and background pair in every context. Results use your configured token stylesheets. Scroll across for all six contexts.
      </p>
      <Organisms.data_table
        id="catalogue-token-contrast-table"
        rows={contrast_rows(@values)}
        row_id={&pair_id/1}
        density="compact"
        caption="Required pairs · ratio, minimum and result per context"
      >
        <:col :let={pair} label="Pair">{pair.foreground} on {pair.background}</:col>
        <:col :let={pair} label="Minimum">{pair.minimum}:1</:col>
        <:col
          :let={pair}
          :for={context <- themes()}
          label={theme_name(context) <> " · ratio / result"}
        >
          {verdict(pair.contexts[context])}
        </:col>
      </Organisms.data_table>
    </Organisms.panel>
    """
  end

  defp contrast_rows(values) do
    Enum.map(values.light.pairs, fn pair ->
      contexts =
        Enum.map(themes(), fn context ->
          result =
            Enum.find(values[context].pairs, fn result ->
              result.foreground == pair.foreground and result.background == pair.background
            end)

          {context, result}
        end)

      Map.put(pair, :contexts, contexts)
    end)
  end

  defp pair_id(pair) do
    String.trim_leading(pair.foreground, "--") <>
      "-on-" <> String.trim_leading(pair.background, "--")
  end

  defp verdict(result), do: "#{ratio(result)} · #{if result.pass?, do: "Pass", else: "Fail"}"

  defp themes, do: Enum.map(Armature.Tokens.Values.contexts(), &elem(&1, 0))
  defp theme_name(theme), do: Armature.Tokens.Values.contexts() |> Keyword.fetch!(theme)
  defp ratio(%{ratio: nil, error: error}), do: error
  defp ratio(%{ratio: ratio}), do: :erlang.float_to_binary(ratio, decimals: 2) <> ":1"
end
