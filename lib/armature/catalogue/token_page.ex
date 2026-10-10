defmodule Armature.Catalogue.TokenPage do
  @moduledoc false
  use Phoenix.Component
  alias Armature.Components, as: UI

  attr(:values, :map, required: true)
  attr(:theme, :string, required: true)

  def page(assigns) do
    assigns = assign(assigns, :tokens, Armature.Tokens.all())

    ~H"""
    <div id="catalogue-token-contract">
      <p id="catalogue-token-statement" class={["armature-token-statement"]}>
        Tokens give every component a shared language.
      </p>
      <p>
        Surfaces, rhythm and interaction states work together. These demonstrations use your
        loaded stylesheets. The reference and contrast tables calculate all six contexts from
        the configured files, including consumer overrides. Auto follows your system preference.
      </p>
      <div class={["armature-catalogue-panels"]}>
        <div class={["armature-catalogue-panel-items"]}>
          <.surfaces />
          <.accents />
          <.status_tones />
          <.rail />
          <.typography tokens={@tokens} />
          <.space tokens={@tokens} />
          <.shape />
          <.density />
          <.motion />
          <.contrast values={@values} />
        </div>
      </div>
      <UI.panel id="catalogue-token-reference" heading="Token reference">
        <p>
          Every contract token, its role and its resolved value in each context. Scroll across for all six contexts.
        </p>
        <div class={["armature-table-scroll"]} tabindex="0" role="region" aria-label="Token reference">
          <table class={["armature-table", "armature-token-reference"]}>
            <caption>Complete token contract and context values</caption>
            <thead>
              <tr>
                <th scope="col">Token</th>
                <th scope="col">Group</th>
                <th scope="col">Role</th>
                <th :for={context <- themes()} scope="col">{theme_name(context)}</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={token <- @tokens} id={"token-#{String.trim_leading(token.name, "--")}"}>
                <th scope="row"><code>{token.name}</code></th>
                <td>{token.group}</td>
                <td>{token.role}</td>
                <td :for={context <- themes()} data-context={context}>
                  {Map.fetch!(@values[context].values, token.name)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </UI.panel>
    </div>
    """
  end

  defp surfaces(assigns) do
    ~H"""
    <UI.panel id="catalogue-token-surfaces" heading="Surfaces and text">
      <UI.stack data-token-group="colour">
        <div
          :for={surface <- ~w(paper canvas stripe hover selected)}
          class={["armature-token-surface"]}
          style={"background: var(--armature-#{surface})"}
        >
          <strong>{String.capitalize(surface)} surface · primary ink</strong>
          <p class={["armature-token-muted"]}>Supporting text remains readable here.</p>
          <UI.link href="#catalogue-token-reference">Accent link · view reference</UI.link>
        </div>
        <div
          class={["armature-token-image"]}
          role="img"
          aria-label="Image placeholder on the image backdrop"
        >
          Image placeholder · image backdrop
        </div>
        <p>Surface boundaries use the decorative line; controls use their stronger border tokens.</p>
      </UI.stack>
    </UI.panel>
    """
  end

  defp accents(assigns) do
    assigns =
      assign(assigns, :rows, [%{id: "selected", name: "Selected record · current choice"}])

    ~H"""
    <UI.panel id="catalogue-token-accents" heading="Accents, focus and selection">
      <UI.stack>
        <UI.button id="catalogue-focus-sample">
          Accent action · focus ring shown
        </UI.button>
        <p>The ring shows focus colour, width and offset. Use Tab to exercise keyboard focus.</p>
        <UI.data_table
          id="catalogue-token-selection"
          rows={@rows}
          caption="Selected row · marked by a cue and an accessible pressed state"
          select_event="catalogue:token-demo"
          selected_id="selected"
          inspector_id="catalogue-token-inspector"
        >
          <:col :let={row} label="Record" row_label>{row.name}</:col>
        </UI.data_table>
        <UI.notice id="catalogue-token-cue" title="Notice rule">
          The cue width also marks this notice, independently of its surface colour.
        </UI.notice>
        <UI.field
          type="select"
          id="catalogue-token-select"
          label="Native select · token chevron strokes, angle and position"
          options={["Available", "Deferred"]}
          value="Available"
        />
        <UI.input
          id="catalogue-token-input"
          aria-label="Input boundary sample"
          value="Visible input boundary"
        />
      </UI.stack>
    </UI.panel>
    """
  end

  defp status_tones(assigns) do
    ~H"""
    <UI.panel id="catalogue-token-status" heading="Status tones">
      <UI.stack>
        <div :for={tone <- ~w(success warning error)}>
          <UI.status tone={tone} label={String.capitalize(tone)} />
          <UI.notice id={"catalogue-token-#{tone}"} tone={tone} title={String.capitalize(tone)}>
            {status_description(tone)} · emphasis text and rule on the matching surface.
          </UI.notice>
        </div>
        <p>Chips and notices name the outcome; colour supplies a second cue.</p>
      </UI.stack>
    </UI.panel>
    """
  end

  defp rail(assigns) do
    ~H"""
    <UI.panel id="catalogue-token-rail" heading="Rail">
      <UI.cluster>
        <div
          :for={width <- ~w(wide narrow)}
          class={["armature-token-rail", "armature-token-rail-#{width}"]}
        >
          <UI.side_nav
            id={"catalogue-token-rail-#{width}"}
            title="Library"
            subtitle={width <> " rail"}
            label={width <> " rail demonstration"}
            items={[
              %{label: "Current section", href: "#catalogue-token-rail", current: true},
              %{label: "Other section", href: "#catalogue-token-reference"}
            ]}
          >
            <:footnote>Supporting rail text</:footnote>
          </UI.side_nav>
        </div>
      </UI.cluster>
      <p>
        Wide and narrow rail widths, wordmark typography, divider and link spacing.
        Tab through both links to compare the rail focus ring and the inset current-pill ring.
        The surrounding app shell demonstrates shell height, content inset and top-bar spacing.
      </p>
      <div class={["armature-token-secondary-nav"]}>
        <UI.grouped_nav
          id="catalogue-token-secondary"
          label="Secondary navigation specimen"
          event="catalogue:token-demo"
          groups={[
            %{
              label: "Components",
              items: [
                %{label: "Controls", href: "#catalogue-token-accents", current: true},
                %{label: "Tables", href: "#catalogue-token-density"}
              ]
            }
          ]}
        />
      </div>
      <p>
        Secondary navigation uses its preferred column width; the surrounding container switches it to a picker when narrow.
      </p>
    </UI.panel>
    """
  end

  attr(:tokens, :list, required: true)

  defp typography(assigns) do
    ~H"""
    <UI.panel id="catalogue-token-typography" heading="Typography">
      <UI.stack data-token-group="typography">
        <div :for={token <- Enum.filter(@tokens, &String.starts_with?(&1.name, "--armature-text-"))}>
          <p class={["armature-token-label"]}>{token.name} · {token.role}</p>
          <p
            :for={weight <- ~w(normal emphasis)}
            class={["armature-token-type"]}
            style={"font-size: var(#{token.name}); font-weight: var(--armature-weight-#{weight})"}
          >
            {String.capitalize(weight)} · Clear records for everyday work.
          </p>
        </div>
        <UI.eyebrow>Contextual eyebrow · tracked text</UI.eyebrow>
        <p>Prose uses the sans family and line-height token, keeping wrapped lines easy to follow.</p>
        <code class={["armature-token-code"]}>record_001 = 128.00</code>
        <p id="catalogue-tabular-sample" class={["armature-token-tabular"]}>
          Tabular numerals: 111.00 · 888.00 · 0123456789
        </p>
        <p>
          Wordmark weight and tracking appear on the rail specimens; page-heading size appears above.
        </p>
      </UI.stack>
    </UI.panel>
    """
  end

  attr(:tokens, :list, required: true)

  defp space(assigns) do
    ~H"""
    <UI.panel id="catalogue-token-space" heading="Space and rhythm">
      <UI.stack data-token-group="space">
        <div :for={
          token <- Enum.filter(@tokens, &Regex.match?(~r/--armature-space-(zero|half|\d+)$/, &1.name))
        }>
          <p class={["armature-token-label"]}>{token.name} · {token.role}</p>
          <div class={["armature-token-space"]} style={"width: var(#{token.name})"} aria-hidden="true">
          </div>
        </div>
        <UI.stack>
          <strong>Stacked content · default gap</strong>
          <p>Related details share a consistent rhythm.</p>
          <UI.cluster>
            <UI.button variant="secondary">Related action</UI.button>
            <UI.status label="Available" tone="success" />
          </UI.cluster>
        </UI.stack>
        <UI.grid id="catalogue-token-wrap">
          <div class={["armature-token-surface"]}>First group</div>
          <div class={["armature-token-surface"]}>Second group</div>
          <div class={["armature-token-surface"]}>Third group</div>
        </UI.grid>
        <p>
          This grid wraps at the layout minimum width. Panel, notice, chip, input and button
          insets are visible in the neighbouring specimens; inspector details use their own rhythm.
          The zero bar has no width and the accessible-only labels have no margin or padding.
        </p>
      </UI.stack>
    </UI.panel>
    """
  end

  defp shape(assigns) do
    ~H"""
    <UI.panel id="catalogue-token-shape" heading="Shape">
      <UI.stack data-token-group="shape">
        <UI.status label="Small chip radius" />
        <UI.button variant="secondary">Base control radius</UI.button>
        <div class={["armature-token-surface"]}>Panel radius and visible border width</div>
        <UI.button id="catalogue-token-pressed">
          Pressed action · offset shown
        </UI.button>
        <UI.button id="catalogue-token-hover">
          Hovered action · ink mix shown
        </UI.button>
        <p>
          Forced pressed and hovered states show displacement and the subtle ink blend.
          The select above demonstrates chevron geometry; the density tables demonstrate
          inactive sort opacity and the fully opaque active direction.
        </p>
        <UI.button aria-describedby="catalogue-token-hidden">
          Accessible description
        </UI.button>
        <span id="catalogue-token-hidden" class={["armature-sr-only"]}>
          This description uses the hidden size and clipping inset tokens.
        </span>
        <p>
          The button description is clipped visually with the hidden size and inset, and remains available to assistive technology.
        </p>
      </UI.stack>
    </UI.panel>
    """
  end

  defp density(assigns) do
    assigns =
      assign(assigns, :rows, [
        %{id: "one", name: "First record", amount: "111.00"},
        %{id: "two", name: "Second record", amount: "888.00"}
      ])

    ~H"""
    <UI.panel id="catalogue-token-density" heading="Density and targets">
      <UI.stack data-token-group="control">
        <UI.table_toolbar id="catalogue-token-search" search_event="catalogue:token-demo" total={2} />
        <UI.data_table
          :for={density <- ~w(default compact)}
          id={"catalogue-density-#{density}"}
          rows={@rows}
          density={density}
          caption={String.capitalize(density) <> " rows · cell padding and minimum height"}
          sort_event="catalogue:token-demo"
          sort_by="name"
        >
          <:col :let={row} label="Record" sort_key="name">{row.name}</:col>
          <:col :let={row} label="Amount" sort_key="amount" numeric>{row.amount}</:col>
        </UI.data_table>
        <UI.cluster>
          <UI.button id="catalogue-token-control-default" variant="secondary">Default control</UI.button>
          <div data-density="compact"><UI.button variant="secondary">Compact control</UI.button></div>
          <UI.button id="catalogue-token-target">44px enhanced target</UI.button>
        </UI.cluster>
        <p>
          Compact controls and sortable headings retain coarse-pointer targets of at least 44px.
          Search uses its preferred width and shrinks to fit. Record shows the active
          arrow; Amount shows the inactive arrow. These specimens keep their two records.
        </p>
        <div class={["armature-token-inspector"]}>
          <UI.inspector id="catalogue-token-inspector" title="Inspector width">
            <UI.facts>
              <:fact label="Record">First record</:fact>
              <:fact label="State">Available</:fact>
            </UI.facts>
          </UI.inspector>
        </div>
        <p>The inspector uses its preferred column width, panel inset and detail spacing.</p>
      </UI.stack>
    </UI.panel>
    """
  end

  defp motion(assigns) do
    ~H"""
    <UI.panel id="catalogue-token-motion" heading="Motion">
      <div id="catalogue-motion-demo" data-token-group="motion">
        <p>Focus or hover this demonstration to run a single transition. Move away to reset.</p>
        <UI.button variant="secondary" aria-describedby="catalogue-motion-caption">Run motion samples</UI.button>
        <div class={["armature-token-motion-track"]}>
          <span class={["armature-token-motion-fast"]}>Fast feedback</span>
        </div>
        <div class={["armature-token-motion-track"]}>
          <span class={["armature-token-motion-base"]}>Base feedback</span>
        </div>
        <p id="catalogue-motion-caption">
          Fast and base samples move using their duration tokens and shared easing.
          Reduced motion stops displacement; reduced duration and iteration tokens limit feedback.
        </p>
      </div>
    </UI.panel>
    """
  end

  attr(:values, :map, required: true)

  defp contrast(assigns) do
    ~H"""
    <UI.panel id="catalogue-token-contrast" heading="Contrast">
      <p>
        Every required foreground and background pair in every context. Results use your configured token stylesheets. Scroll across for all six contexts.
      </p>
      <div
        class={["armature-table-scroll"]}
        tabindex="0"
        role="region"
        aria-label="Required contrast results"
      >
        <table class={["armature-table", "armature-token-pairs"]}>
          <caption>Required pairs · ratio, minimum and result per context</caption>
          <thead>
            <tr>
              <th scope="col">Pair</th>
              <th scope="col">Minimum</th>
              <th :for={context <- themes()} scope="col">{theme_name(context)} · ratio / result</th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={pair <- contrast_rows(@values)}
              data-foreground={pair.foreground}
              data-background={pair.background}
            >
              <th scope="row">{pair.foreground} on {pair.background}</th>
              <td>{pair.minimum}:1</td>
              <td :for={{context, result} <- pair.contexts} data-theme={context}>
                {ratio(result)} · {if result.pass?, do: "Pass", else: "Fail"}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </UI.panel>
    """
  end

  defp status_description("success"), do: "Ready to continue"
  defp status_description("warning"), do: "Review before continuing"
  defp status_description("error"), do: "Correct the problem to continue"

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

  defp themes, do: Enum.map(Armature.Tokens.Values.contexts(), &elem(&1, 0))
  defp theme_name(theme), do: Armature.Tokens.Values.contexts() |> Keyword.fetch!(theme)
  defp ratio(%{ratio: nil, error: error}), do: error
  defp ratio(%{ratio: ratio}), do: :erlang.float_to_binary(ratio, decimals: 2) <> ":1"
end
