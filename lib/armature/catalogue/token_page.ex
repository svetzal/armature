defmodule Armature.Catalogue.TokenPage do
  @moduledoc false
  use Phoenix.Component

  attr(:values, :map, required: true)
  attr(:theme, :string, required: true)

  def page(assigns) do
    tokens = Armature.Tokens.all()
    assigns = assign(assigns, groups: Enum.uniq_by(tokens, & &1.group), tokens: tokens)

    ~H"""
    <div id="catalogue-token-contract">
      <p>
        Tokens are the foundation of every component. Samples use your loaded stylesheets.
        Values and contrast results are calculated on the server from the configured files.
        Auto follows your system preference; explicit themes use the catalogue theme control.
      </p>
      <section :for={group <- @groups} id={"catalogue-token-group-#{group.group}"}>
        <h2>{group_name(group.group)}</h2>
        <div class={["armature-token-grid"]}>
          <article
            :for={token <- Enum.filter(@tokens, &(&1.group == group.group))}
            id={"token-#{String.trim_leading(token.name, "--")}"}
            class={["armature-token-card"]}
          >
            <h3>{token.name}</h3>
            <p>{token.role}</p>
            <dl>
              <%= for theme <- themes() do %>
                <dt>{theme_name(theme)}</dt>
                <dd>{Map.fetch!(@values[theme].values, token.name)}</dd>
              <% end %>
            </dl>
            <div
              :if={token.group == :colour}
              class={["armature-token-swatch"]}
              style={"background: var(#{token.name})"}
              role="img"
              aria-label={"Colour sample for #{token.name}. #{token.role}"}
            >
            </div>
            <%= if token.group == :colour and token.contrast != [] do %>
              <div class={["armature-table-scroll"]}>
                <table class={["armature-table", "armature-token-pairs"]}>
                  <caption>Required contrast for {token.name}</caption>
                  <thead>
                    <tr>
                      <th scope="col">Theme</th>
                      <th scope="col">Background</th>
                      <th scope="col">Ratio</th>
                      <th scope="col">Minimum</th>
                      <th scope="col">Result</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for theme <- themes(), pair <- Enum.filter(@values[theme].pairs, &(&1.foreground == token.name)) do %>
                      <tr data-theme={theme}>
                        <th scope="row">{theme_name(theme)}</th>
                        <td>{pair.background}</td>
                        <td>{ratio(pair)}</td>
                        <td>{pair.minimum}:1</td>
                        <td>{if pair.pass?, do: "Pass", else: "Fail"}</td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>
            <%= if String.starts_with?(token.name, "--armature-text-") do %>
              <div
                :for={weight <- ~w(normal emphasis)}
                class={["armature-token-type"]}
                style={"font-size: var(#{token.name}); font-weight: var(--armature-weight-#{weight})"}
              >
                <p>Clear type for everyday reading · 0123456789</p>
                <p class={["armature-token-label"]}>
                  Weight: --armature-weight-{weight} ({weight_value(@values, @theme, weight)})
                </p>
              </div>
            <% end %>
            <div
              :if={String.starts_with?(token.name, "--armature-space-")}
              class={["armature-token-space"]}
              style={"width: var(#{token.name})"}
              role="img"
              aria-label={"Spacing bar for #{token.name}; values listed above."}
            >
            </div>
            <div
              :if={String.starts_with?(token.name, "--armature-radius-")}
              class={["armature-token-radius"]}
              style={"border-radius: var(#{token.name})"}
              role="img"
              aria-label={"Corner shape for #{token.name}; values listed above."}
            >
            </div>
            <div
              :if={String.contains?(token.name, ["control-height", "table-row-height"])}
              class={["armature-token-height"]}
              style={"height: var(#{token.name})"}
              role="img"
              aria-label={"Density sample for #{token.name}; values listed above."}
            >
            </div>
            <div
              :if={token.name == "--armature-cue-width"}
              class={["armature-token-cue"]}
              role="img"
              aria-label="Selection cue width; value listed above."
            >
            </div>
          </article>
        </div>
      </section>
      <section aria-labelledby="catalogue-token-controls">
        <h2 id="catalogue-token-controls">Numbers and keyboard focus</h2>
        <p id="catalogue-tabular-sample" class={["armature-token-tabular"]}>
          Tabular numerals: 0123456789 · 111.00 · 888.00
        </p>
        <p>The sample control shows the focus width and offset. Use Tab to focus it.</p>
        <Armature.Components.button id="catalogue-focus-sample" class={["armature-token-focus"]}>
          Focus ring sample
        </Armature.Components.button>
      </section>
    </div>
    """
  end

  defp themes, do: [:light, :dark, :explicit_light, :explicit_dark]
  defp theme_name(:light), do: "Light (Auto)"
  defp theme_name(:dark), do: "Dark (Auto)"
  defp theme_name(:explicit_light), do: "Light (explicit)"
  defp theme_name(:explicit_dark), do: "Dark (explicit)"

  defp weight_value(values, "auto", weight) do
    name = "--armature-weight-#{weight}"
    "Auto light: #{values.light.values[name]}; Auto dark: #{values.dark.values[name]}"
  end

  defp weight_value(values, theme, weight) do
    key = if theme == "dark", do: :explicit_dark, else: :explicit_light
    values[key].values["--armature-weight-#{weight}"]
  end

  defp group_name(:control), do: "Control and density"
  defp group_name(group), do: group |> to_string() |> String.capitalize()
  defp ratio(%{ratio: nil, error: error}), do: error
  defp ratio(%{ratio: ratio}), do: :erlang.float_to_binary(ratio, decimals: 2) <> ":1"
end
