defmodule Armature.Catalogue.BaselineExamples do
  @moduledoc "Neutral, interactive demonstrations of every node in `Armature.UI.Registry`."
  @behaviour Armature.Catalogue.Examples
  use Phoenix.Component
  alias Armature.Components.Atoms
  alias Armature.Components.Layouts
  alias Armature.Components.Molecules
  alias Armature.Components.Organisms
  alias Armature.Components.Templates
  alias Armature.Catalogue.Records

  @themes Armature.Components.themes()

  @impl true
  def examples(id) do
    case Enum.find(Armature.UI.Registry.nodes(), &(&1.id == id)) do
      nil ->
        []

      node ->
        [
          %{
            title: "#{id} in use",
            description: description(id),
            render: fn assigns -> demo(assign(assigns, :node, node)) end
          }
        ]
    end
  end

  @impl true
  def init do
    selected = Enum.min_by(Records.all(), & &1.name)

    refresh(%{
      query: "",
      sort_by: "name",
      sort_direction: "asc",
      page: 1,
      page_size: 25,
      selected: selected,
      selected_id: selected.id,
      selection_label: "Selected #{selected.id}, #{selected.name}.",
      form: to_form(%{"name" => "", "accepted" => false}, as: :sample),
      saved: false,
      theme: "auto",
      destination: "",
      count: 0
    })
  end

  @impl true
  def handle_event("example:theme", %{"theme" => theme}, state) when theme in @themes,
    do: %{state | theme: theme}

  def handle_event("example:choose", %{"destination" => destination}, state),
    do: %{state | destination: destination}

  def handle_event("example:action", _params, state), do: %{state | count: state.count + 1}

  def handle_event(event, %{"sample" => params}, state)
      when event in ~w(example:validate example:save) do
    errors =
      if String.trim(params["name"] || "") == "", do: [name: {"Enter a name.", []}], else: []

    %{
      state
      | form: to_form(params, as: :sample, errors: errors),
        saved: event == "example:save" && errors == []
    }
  end

  def handle_event("record_search", %{"query" => query}, state),
    do: refresh(%{state | query: query, page: 1})

  def handle_event("record_sort", %{"key" => key}, state) when key in ~w(name score) do
    direction = if state.sort_by == key && state.sort_direction == "asc", do: "desc", else: "asc"
    refresh(%{state | sort_by: key, sort_direction: direction, page: 1})
  end

  def handle_event("record_page", %{"page" => page}, state) do
    case Integer.parse(page) do
      {number, ""} -> refresh(%{state | page: number})
      _ -> state
    end
  end

  def handle_event("record_size", %{"page_size" => size}, state) when size in ~w(10 25 50),
    do: refresh(%{state | page_size: String.to_integer(size), page: 1})

  def handle_event("record_select", %{"id" => id}, state) do
    case Enum.find(Records.all(), &(&1.id == id)) do
      nil ->
        state

      record ->
        %{
          state
          | selected: record,
            selected_id: id,
            selection_label: "Selected #{id}, #{record.name}."
        }
    end
  end

  def handle_event(_event, _params, state), do: state

  defp refresh(state) do
    records = Records.page(state)
    Map.merge(state, %{records: records, page: records.page})
  end

  defp example_nav do
    [
      %{label: "Overview", href: "#catalogue-usage", current: true},
      %{label: "Guidance", href: "#catalogue-used-by", current: false}
    ]
  end

  defp description(:button),
    do: "Primary, secondary and disabled actions; activation updates a local count."

  defp description(:status),
    do: "Neutral, success, warning and error tones each express state in words."

  defp description(:field),
    do:
      "Hint, validation, select, textarea, checkbox and disabled controls. Submit an empty name to see an error."

  defp description(:theme_switch),
    do:
      "System, Light and Dark as native radios. The second switch shows its legend; both share one choice."

  defp description(:notice), do: "Static guidance, polite results and error alerts."

  defp description(id) when id in [:stack, :cluster, :grid, :split],
    do: "Resize the page to explore wrapping and arrangement."

  defp description(id) when id in [:data_table, :table_toolbar, :pagination, :table_inspector],
    do:
      "Synthetic records in compact density with local search, sorting, paging and selection. State carries across examples."

  defp description(_id), do: "A named native control or region using the current theme."

  attr(:state, :map, required: true)
  attr(:node, Armature.Registry.Node, required: true)

  defp demo(assigns) do
    ~H"""
    <%= case @node.level do %>
      <% :atom -> %>
        <.atom_demo id={@node.id} state={@state} />
      <% :layout -> %>
        <.layout_demo id={@node.id} state={@state} />
      <% :molecule -> %>
        <.molecule_demo id={@node.id} state={@state} />
      <% :organism -> %>
        <.organism_demo id={@node.id} state={@state} />
      <% :template -> %>
        <.template_demo id={@node.id} state={@state} />
    <% end %>
    """
  end

  attr(:state, :map, required: true)
  attr(:id, :atom, required: true)

  defp atom_demo(assigns) do
    ~H"""
    <%= case @id do %>
      <% :eyebrow -> %>
        <Atoms.eyebrow>Library / Examples</Atoms.eyebrow>
      <% :button -> %>
        <Layouts.cluster>
          <Atoms.button id="example-action" phx-click="example:action">Activate</Atoms.button>
          <Atoms.button variant="secondary" phx-click="example:action">Secondary action</Atoms.button>
          <Atoms.button disabled>Unavailable</Atoms.button>
          <Atoms.button variant="secondary" disabled>Unavailable secondary</Atoms.button>
        </Layouts.cluster>
        <p role="status">Activated {@state.count} times.</p>
      <% :link -> %>
        <Atoms.link href="#catalogue-usage">Read usage notes</Atoms.link>
      <% :icon -> %>
        <Atoms.button aria-label="Add example" phx-click="example:action">
          <Atoms.icon>
            <svg viewBox="0 0 24 24" focusable="false"><path d="M12 4v16M4 12h16" /></svg>
          </Atoms.icon>
          Add example
        </Atoms.button>
        <p role="status">Added {@state.count} examples.</p>
      <% :input -> %>
        <label for="example-input">Example name</label>
        <Atoms.input id="example-input" value="Sample" />
        <label for="example-input-disabled">Disabled name</label>
        <Atoms.input id="example-input-disabled" value="Sample" disabled />
      <% :select -> %>
        <label for="example-select">Size</label>
        <Atoms.select
          id="example-select"
          options={[{"Small", "s"}, {"Large", "l"}]}
          prompt="Choose a size"
        />
      <% :textarea -> %>
        <label for="example-textarea">Notes</label>
        <Atoms.textarea id="example-textarea" value="Synthetic notes" />
      <% :status -> %>
        <Layouts.cluster>
          <Atoms.status
            :for={tone <- ~w(neutral success warning error)}
            tone={tone}
            label={String.capitalize(tone)}
          />
        </Layouts.cluster>
    <% end %>
    """
  end

  attr(:state, :map, required: true)
  attr(:id, :atom, required: true)

  defp layout_demo(assigns) do
    ~H"""
    <%= case @id do %>
      <% :stack -> %>
        <Layouts.stack>
          <p>First item</p><p>Second item</p><p>Third item</p>
        </Layouts.stack>
      <% :cluster -> %>
        <Layouts.cluster>
          <Atoms.status :for={number <- 1..8} label={"Item #{number}"} />
        </Layouts.cluster>
      <% :grid -> %>
        <Layouts.grid>
          <p :for={number <- 1..6}>Cell {number}</p>
        </Layouts.grid>
      <% :split -> %>
        <Layouts.split>
          <p>Main region</p><:secondary>
            <p>Secondary region</p>
          </:secondary>
        </Layouts.split>
    <% end %>
    """
  end

  attr(:state, :map, required: true)
  attr(:id, :atom, required: true)

  defp molecule_demo(assigns) do
    ~H"""
    <%= case @id do %>
      <% :page_heading -> %>
        <Molecules.page_heading
          id="example-page-heading"
          title="Example page"
          eyebrow="Library / Examples"
        >
          <:actions><Atoms.status label="Ready" /></:actions>
        </Molecules.page_heading>
      <% :theme_switch -> %>
        <Layouts.stack>
          <Molecules.theme_switch id="example-theme" value={@state.theme} event="example:theme" />
          <Molecules.theme_switch
            id="example-theme-labelled"
            value={@state.theme}
            label="Appearance"
            label_visible
            event="example:theme"
          />
        </Layouts.stack>
        <p role="status">Selected theme: {@state.theme}</p>
      <% :field -> %>
        <.form
          for={@state.form}
          id="sample-form"
          phx-change="example:validate"
          phx-submit="example:save"
        >
          <Layouts.stack>
            <Molecules.field field={@state.form[:name]} label="Name" hint="The name people will see." />
            <Molecules.field
              field={@state.form[:size]}
              type="select"
              label="Size"
              prompt="Choose a size"
              options={[{"Small", "s"}, {"Large", "l"}]}
            />
            <Molecules.field field={@state.form[:notes]} type="textarea" label="Notes" />
            <Molecules.field field={@state.form[:accepted]} type="checkbox" label="Accept terms" />
            <Molecules.field
              id="example-error"
              label="Invalid example"
              value=""
              errors={["Enter a value."]}
            />
            <Molecules.field id="example-disabled" label="Disabled example" value="Fixed" disabled />
            <Atoms.button type="submit">Save</Atoms.button>
            <Molecules.notice :if={@state.saved} id="example-saved" tone="success" result>
              Saved for this preview.
            </Molecules.notice>
          </Layouts.stack>
        </.form>
      <% :notice -> %>
        <Layouts.stack>
          <Molecules.notice id="example-static" title="Information">
            Static guidance has no live region.
          </Molecules.notice>
          <Molecules.notice id="example-result" tone="success" result title="Saved">
            Announced politely.
          </Molecules.notice>
          <Molecules.notice id="example-warning" tone="warning" title="Review">
            Check your example values.
          </Molecules.notice>
          <Molecules.notice id="example-failure" tone="error" result title="Could not save">
            An error result is an alert.
          </Molecules.notice>
        </Layouts.stack>
      <% :facts -> %>
        <Molecules.facts>
          <:fact label="Identifier">R-001</:fact>
          <:fact label="Score">42</:fact>
          <:fact label="State"><Atoms.status label="Available" tone="success" /></:fact>
        </Molecules.facts>
      <% :table_toolbar -> %>
        <Molecules.table_toolbar
          id="example-toolbar"
          query={@state.query}
          total={@state.records.total}
          search_event="record_search"
        >
          <:actions><Atoms.button phx-click="example:action">Add example</Atoms.button></:actions>
        </Molecules.table_toolbar>
        <p role="status">Added {@state.count} examples.</p>
      <% :pagination -> %>
        <Molecules.pagination
          id="example-pagination"
          page={@state.page}
          pages={@state.records.pages}
          first={@state.records.first}
          last={@state.records.last}
          total={@state.records.total}
          page_event="record_page"
          page_size={@state.page_size}
          page_sizes={[10, 25, 50]}
          size_event="record_size"
        />
      <% :record_header -> %>
        <Molecules.record_header
          id="example-header"
          title="Example record"
          context="R-001"
          status="Available"
        >
          <:actions><Atoms.button phx-click="example:action">Review</Atoms.button></:actions>
        </Molecules.record_header>
        <p role="status">Reviewed {@state.count} times.</p>
    <% end %>
    """
  end

  attr(:state, :map, required: true)
  attr(:id, :atom, required: true)

  defp organism_demo(assigns) do
    ~H"""
    <%= case @id do %>
      <% :side_nav -> %>
        <Organisms.side_nav
          id="example-rail"
          title="Library"
          subtitle="Example application"
          label="Example sections"
          section_label="Sections"
          items={example_nav()}
        >
          <:mark>
            <svg viewBox="0 0 2 5" fill="currentColor"><path d="M1 0 2 2.5 1 5 0 2.5Z" /></svg>
          </:mark>
          <:footnote>Synthetic content</:footnote>
        </Organisms.side_nav>
      <% :top_bar -> %>
        <Organisms.top_bar context="Library / Examples">
          <:actions><Atoms.button phx-click="example:action">Activate</Atoms.button></:actions>
        </Organisms.top_bar>
        <p role="status">Activated {@state.count} times.</p>
      <% :grouped_nav -> %>
        <Organisms.grouped_nav
          id="example-grouped"
          label="Example components"
          event="example:choose"
          groups={[%{label: "Examples", items: example_nav()}]}
        />
        <p role="status">Selected destination: {@state.destination}</p>
      <% :panel -> %>
        <Layouts.grid>
          <Organisms.panel id="example-panel" heading="Example panel">
            <:actions><Atoms.button phx-click="example:action">Activate</Atoms.button></:actions>
            <p role="status">Activated {@state.count} times.</p>
          </Organisms.panel>
          <Organisms.panel id="example-empty-panel" heading="Empty panel">
            <Molecules.notice id="example-empty-notice" title="No items">
              Add an item to begin.
            </Molecules.notice>
          </Organisms.panel>
        </Layouts.grid>
      <% :data_table -> %>
        <Organisms.data_table
          id="example-table"
          density="compact"
          rows={@state.records.rows}
          caption="Synthetic records"
          sort_by={@state.sort_by}
          sort_direction={@state.sort_direction}
          sort_event="record_sort"
          select_event="record_select"
          selected_id={@state.selected_id}
          inspector_id="example-details"
        >
          <:col :let={row} label="Name" sort_key="name" row_label>
            {row.name}{" "}<small>{row.group}</small>
          </:col>
          <:col :let={row} label="Score" numeric sort_key="score">{row.score}</:col>
        </Organisms.data_table>
        <Organisms.inspector id="example-details" title="Selected record">
          <.details state={@state} />
        </Organisms.inspector>
        <Organisms.data_table id="example-empty-table" rows={[]} caption="Empty records">
          <:col label="Name" />
        </Organisms.data_table>
        <h3>Default density</h3>
        <Organisms.data_table
          id="example-table-default"
          rows={Enum.take(@state.records.rows, 3)}
          caption="Default density records"
        >
          <:col :let={row} label="Identifier">{row.id}</:col>
          <:col :let={row} label="Name" row_label>{row.name}{" "}<small>{row.group}</small></:col>
          <:col :let={row} label="Score" numeric>{row.score}</:col>
        </Organisms.data_table>
      <% :inspector -> %>
        <Atoms.button phx-click="record_select" phx-value-id="R-001">Inspect R-001</Atoms.button>
        <Organisms.inspector id="example-inspector" title="Example details">
          <.details state={@state} />
        </Organisms.inspector>
    <% end %>
    """
  end

  attr(:state, :map, required: true)
  attr(:id, :atom, required: true)

  defp template_demo(assigns) do
    ~H"""
    <%= case @id do %>
      <% :app_shell -> %>
        <Templates.app_shell
          id="example-shell"
          title="Library"
          nav_label="Example sections"
          section_label="Sections"
          heading="Example page"
          heading_id="example-shell-heading"
          eyebrow="Library / Examples"
          context="Library / Examples"
          items={example_nav()}
        >
          <:footnote>Synthetic content</:footnote>
          <:top_actions>
            <Molecules.theme_switch
              id="example-shell-theme"
              value={@state.theme}
              event="example:theme"
            />
          </:top_actions>
          <Organisms.panel id="example-shell-panel" heading="Content">
            <p>A recomposable application shell.</p>
          </Organisms.panel>
        </Templates.app_shell>
      <% :table_inspector -> %>
        <Templates.table_inspector
          id="example-records"
          density="compact"
          rows={@state.records.rows}
          caption="Synthetic records"
          query={@state.query}
          search_event="record_search"
          total={@state.records.total}
          sort_by={@state.sort_by}
          sort_direction={@state.sort_direction}
          sort_event="record_sort"
          selected_id={@state.selected_id}
          select_event="record_select"
          selection_label={@state.selection_label}
          page={@state.page}
          pages={@state.records.pages}
          first={@state.records.first}
          last={@state.records.last}
          page_event="record_page"
          page_size={@state.page_size}
          page_sizes={[10, 25, 50]}
          size_event="record_size"
        >
          <:col :let={row} label="Identifier">{row.id}</:col>
          <:col :let={row} label="Name" sort_key="name" row_label>
            {row.name}{" "}<small>{row.group}</small>
          </:col>
          <:col :let={row} label="Score" numeric sort_key="score">{row.score}</:col>
          <:details><.details state={@state} /></:details>
        </Templates.table_inspector>
    <% end %>
    """
  end

  attr(:state, :map, required: true)

  defp details(assigns) do
    ~H"""
    <%= if @state.selected do %>
      <Molecules.record_header
        id="example-selected-record"
        title={@state.selected.name}
        context={@state.selected.id}
        status="Available"
      />
      <Molecules.facts>
        <:fact label="Group">{@state.selected.group}</:fact>
        <:fact label="Score">{@state.selected.score}</:fact>
      </Molecules.facts>
      <p :if={!Enum.any?(@state.records.rows, &(&1.id == @state.selected_id))}>
        The selected record is outside the current results.
      </p>
    <% else %>
      <p>Select a record to see its details.</p>
    <% end %>
    """
  end
end
