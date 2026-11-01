defmodule Armature.Catalogue.TokenPage do
  @moduledoc false
  use Phoenix.Component
  alias Armature.Components.Atoms
  alias Armature.Components.Layouts
  alias Armature.Components.Molecules
  alias Armature.Components.Organisms
  alias Armature.Catalogue.TokenTables

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
          <TokenTables.contrast values={@values} />
        </div>
      </div>
      <TokenTables.reference tokens={@tokens} values={@values} />
    </div>
    """
  end

  defp surfaces(assigns) do
    ~H"""
    <Organisms.panel id="catalogue-token-surfaces" heading="Surfaces and text">
      <Layouts.stack data-token-group="colour">
        <div
          :for={surface <- ~w(paper canvas stripe hover selected)}
          class={["armature-token-surface"]}
          style={"background: var(--armature-#{surface})"}
        >
          <strong>{String.capitalize(surface)} surface · primary ink</strong>
          <p class={["armature-token-muted"]}>Supporting text remains readable here.</p>
          <Atoms.link href="#catalogue-token-reference">Accent link · view reference</Atoms.link>
        </div>
        <div
          class={["armature-token-image"]}
          role="img"
          aria-label="Image placeholder on the image backdrop"
        >
          Image placeholder · image backdrop
        </div>
        <p>Surface boundaries use the decorative line; controls use their stronger border tokens.</p>
      </Layouts.stack>
    </Organisms.panel>
    """
  end

  defp accents(assigns) do
    assigns =
      assign(assigns, :rows, [%{id: "selected", name: "Selected record · current choice"}])

    ~H"""
    <Organisms.panel id="catalogue-token-accents" heading="Accents, focus and selection">
      <Layouts.stack>
        <Atoms.button id="catalogue-focus-sample">
          Accent action · focus ring shown
        </Atoms.button>
        <p>The ring shows focus colour, width and offset. Use Tab to exercise keyboard focus.</p>
        <Organisms.data_table
          id="catalogue-token-selection"
          rows={@rows}
          caption="Selected row · marked by a cue and an accessible pressed state"
          select_event="catalogue:token-demo"
          selected_id="selected"
          inspector_id="catalogue-token-inspector"
        >
          <:col :let={row} label="Record" row_label>{row.name}</:col>
        </Organisms.data_table>
        <Molecules.notice id="catalogue-token-cue" title="Notice rule">
          The cue width also marks this notice, independently of its surface colour.
        </Molecules.notice>
        <Molecules.field
          type="select"
          id="catalogue-token-select"
          label="Native select · token chevron strokes, angle and position"
          options={["Available", "Deferred"]}
          value="Available"
        />
        <Atoms.input
          id="catalogue-token-input"
          aria-label="Input boundary sample"
          value="Visible input boundary"
        />
      </Layouts.stack>
    </Organisms.panel>
    """
  end

  defp status_tones(assigns) do
    ~H"""
    <Organisms.panel id="catalogue-token-status" heading="Status tones">
      <Layouts.stack>
        <div :for={tone <- ~w(success warning error)}>
          <Atoms.status tone={tone} label={String.capitalize(tone)} />
          <Molecules.notice id={"catalogue-token-#{tone}"} tone={tone} title={String.capitalize(tone)}>
            {status_description(tone)} · emphasis text and rule on the matching surface.
          </Molecules.notice>
        </div>
        <p>Chips and notices name the outcome; colour supplies a second cue.</p>
      </Layouts.stack>
    </Organisms.panel>
    """
  end

  defp rail(assigns) do
    ~H"""
    <Organisms.panel id="catalogue-token-rail" heading="Rail">
      <Layouts.cluster>
        <div
          :for={width <- ~w(wide narrow)}
          class={["armature-token-rail", "armature-token-rail-#{width}"]}
        >
          <Organisms.side_nav
            id={"catalogue-token-rail-#{width}"}
            title="Library"
            subtitle={width <> " rail"}
            label={width <> " rail demonstration"}
            section_label="Library"
            items={[
              %{label: "Current section", href: "#catalogue-token-rail", current: true},
              %{label: "Other section", href: "#catalogue-token-reference"}
            ]}
          >
            <:footnote>Supporting rail text</:footnote>
          </Organisms.side_nav>
        </div>
      </Layouts.cluster>
      <p>
        Wide and narrow rail widths, wordmark typography, divider and link spacing.
        Tab through both links to compare the rail focus ring and the inset current-pill ring.
        The surrounding app shell demonstrates shell height, content inset and top-bar spacing.
      </p>
      <div class={["armature-token-secondary-nav"]}>
        <Organisms.grouped_nav
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
    </Organisms.panel>
    """
  end

  attr(:tokens, :list, required: true)

  defp typography(assigns) do
    ~H"""
    <Organisms.panel id="catalogue-token-typography" heading="Typography">
      <Layouts.stack data-token-group="typography">
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
        <Atoms.eyebrow>Contextual eyebrow · tracked text</Atoms.eyebrow>
        <p>Prose uses the sans family and line-height token, keeping wrapped lines easy to follow.</p>
        <code class={["armature-token-code"]}>record_001 = 128.00</code>
        <p id="catalogue-tabular-sample" class={["armature-token-tabular"]}>
          Tabular numerals: 111.00 · 888.00 · 0123456789
        </p>
        <p>
          Wordmark weight and tracking appear on the rail specimens; page-heading size appears above.
        </p>
      </Layouts.stack>
    </Organisms.panel>
    """
  end

  attr(:tokens, :list, required: true)

  defp space(assigns) do
    ~H"""
    <Organisms.panel id="catalogue-token-space" heading="Space and rhythm">
      <Layouts.stack data-token-group="space">
        <div :for={
          token <- Enum.filter(@tokens, &Regex.match?(~r/--armature-space-(zero|half|\d+)$/, &1.name))
        }>
          <p class={["armature-token-label"]}>{token.name} · {token.role}</p>
          <div class={["armature-token-space"]} style={"width: var(#{token.name})"} aria-hidden="true">
          </div>
        </div>
        <Layouts.stack>
          <strong>Stacked content · default gap</strong>
          <p>Related details share a consistent rhythm.</p>
          <Layouts.cluster>
            <Atoms.button variant="secondary">Related action</Atoms.button>
            <Atoms.status label="Available" tone="success" />
          </Layouts.cluster>
        </Layouts.stack>
        <Layouts.grid id="catalogue-token-wrap">
          <div class={["armature-token-surface"]}>First group</div>
          <div class={["armature-token-surface"]}>Second group</div>
          <div class={["armature-token-surface"]}>Third group</div>
        </Layouts.grid>
        <p>
          This grid wraps at the layout minimum width. Panel, notice, chip, input and button
          insets are visible in the neighbouring specimens; inspector details use their own rhythm.
          The zero bar has no width and the accessible-only labels have no margin or padding.
        </p>
      </Layouts.stack>
    </Organisms.panel>
    """
  end

  defp shape(assigns) do
    ~H"""
    <Organisms.panel id="catalogue-token-shape" heading="Shape">
      <Layouts.stack data-token-group="shape">
        <Atoms.status label="Small chip radius" />
        <Atoms.button variant="secondary">Base control radius</Atoms.button>
        <div class={["armature-token-surface"]}>Panel radius and visible border width</div>
        <Atoms.button id="catalogue-token-pressed">
          Pressed action · offset shown
        </Atoms.button>
        <Atoms.button id="catalogue-token-hover">
          Hovered action · ink mix shown
        </Atoms.button>
        <p>
          Forced pressed and hovered states show displacement and the subtle ink blend.
          The select above demonstrates chevron geometry; the density tables demonstrate
          inactive sort opacity and the fully opaque active direction.
        </p>
        <Atoms.button aria-describedby="catalogue-token-hidden">
          Accessible description
        </Atoms.button>
        <span id="catalogue-token-hidden" class={["armature-sr-only"]}>
          This description uses the hidden size and clipping inset tokens.
        </span>
        <p>
          The button description is clipped visually with the hidden size and inset, and remains available to assistive technology.
        </p>
      </Layouts.stack>
    </Organisms.panel>
    """
  end

  defp density(assigns) do
    assigns =
      assign(assigns, :rows, [
        %{id: "one", name: "First record", amount: "111.00"},
        %{id: "two", name: "Second record", amount: "888.00"}
      ])

    ~H"""
    <Organisms.panel id="catalogue-token-density" heading="Density and targets">
      <Layouts.stack data-token-group="control">
        <Molecules.table_toolbar
          id="catalogue-token-search"
          search_event="catalogue:token-demo"
          total={2}
        />
        <Organisms.data_table
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
        </Organisms.data_table>
        <Layouts.cluster>
          <Atoms.button id="catalogue-token-control-default" variant="secondary">Default control</Atoms.button>
          <div data-density="compact">
            <Atoms.button variant="secondary">Compact control</Atoms.button>
          </div>
          <Atoms.button id="catalogue-token-target">44px enhanced target</Atoms.button>
        </Layouts.cluster>
        <p>
          Compact controls and sortable headings retain coarse-pointer targets of at least 44px.
          Search uses its preferred width and shrinks to fit. Record shows the active
          arrow; Amount shows the inactive arrow. These specimens keep their two records.
        </p>
        <div class={["armature-token-inspector"]}>
          <Organisms.inspector id="catalogue-token-inspector" title="Inspector width">
            <Molecules.facts>
              <:fact label="Record">First record</:fact>
              <:fact label="State">Available</:fact>
            </Molecules.facts>
          </Organisms.inspector>
        </div>
        <p>The inspector uses its preferred column width, panel inset and detail spacing.</p>
      </Layouts.stack>
    </Organisms.panel>
    """
  end

  defp motion(assigns) do
    ~H"""
    <Organisms.panel id="catalogue-token-motion" heading="Motion">
      <div id="catalogue-motion-demo" data-token-group="motion">
        <p>Focus or hover this demonstration to run a single transition. Move away to reset.</p>
        <Atoms.button variant="secondary" aria-describedby="catalogue-motion-caption">Run motion samples</Atoms.button>
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
    </Organisms.panel>
    """
  end

  defp status_description("success"), do: "Ready to continue"
  defp status_description("warning"), do: "Review before continuing"
  defp status_description("error"), do: "Correct the problem to continue"
end
