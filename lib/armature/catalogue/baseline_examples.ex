defmodule Armature.Catalogue.BaselineExamples do
  @moduledoc "Neutral, interactive demonstrations of every node in `Armature.UI.Registry`."
  @behaviour Armature.Catalogue.Examples
  use Phoenix.Component
  alias Armature.Components, as: A
  alias Armature.Catalogue.Records

  @impl true
  def examples(id) do
    if Enum.any?(Armature.UI.Registry.nodes(), &(&1.id == id)) do
      [
        %{
          title: "#{id} in use",
          description: description(id),
          render: fn assigns -> demo(assign(assigns, :node, id)) end
        }
      ]
    else
      []
    end
  end

  @impl true
  def init do
    refresh(%{
      query: "",
      sort_by: "name",
      sort_direction: "asc",
      page: 1,
      page_size: 25,
      selected: nil,
      selected_id: nil,
      selection_label: "No record selected.",
      form: to_form(%{"name" => "", "accepted" => false}, as: :sample),
      saved: false,
      count: 0
    })
  end

  @impl true
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

  defp description(:button),
    do: "Primary, secondary and disabled actions; activation updates a local count."

  defp description(:status),
    do: "Neutral, success, warning and error tones each express state in words."

  defp description(:field),
    do:
      "Hint, validation, select, textarea, checkbox and disabled controls. Submit an empty name to see an error."

  defp description(:notice), do: "Static guidance, polite results and error alerts."

  defp description(id) when id in [:stack, :cluster, :grid, :split],
    do: "Resize the page to explore wrapping and arrangement."

  defp description(id) when id in [:data_table, :table_toolbar, :pagination, :table_inspector],
    do:
      "Synthetic records with local search, sorting, paging and selection. State carries across examples."

  defp description(_id), do: "A named native control or region using the current theme."

  attr(:state, :map, required: true)
  attr(:node, :atom, required: true)

  defp demo(assigns) do
    ~H"""
    <%= case @node do %>
      <% :button -> %>
        <A.cluster>
          <A.button id="example-action" phx-click="example:action">Activate</A.button>
          <A.button variant="secondary" phx-click="example:action">Secondary action</A.button>
          <A.button disabled>Unavailable</A.button>
          <A.button variant="secondary" disabled>Unavailable secondary</A.button>
        </A.cluster>
        <p role="status">Activated {@state.count} times.</p>
      <% :link -> %>
        <A.link href="#catalogue-usage">Read usage notes</A.link>
      <% :icon -> %>
        <A.button aria-label="Add example" phx-click="example:action">
          <A.icon>
            <svg viewBox="0 0 24 24" focusable="false"><path d="M12 4v16M4 12h16" /></svg>
          </A.icon>
          Add example
        </A.button>
        <p role="status">Added {@state.count} examples.</p>
      <% :input -> %>
        <label for="example-input">Example name</label>
        <A.input id="example-input" value="Sample" />
        <label for="example-input-disabled">Disabled name</label>
        <A.input id="example-input-disabled" value="Sample" disabled />
      <% :select -> %>
        <label for="example-select">Size</label>
        <A.select
          id="example-select"
          options={[{"Small", "s"}, {"Large", "l"}]}
          prompt="Choose a size"
        />
      <% :textarea -> %>
        <label for="example-textarea">Notes</label>
        <A.textarea id="example-textarea" value="Synthetic notes" />
      <% :status -> %>
        <A.cluster>
          <A.status
            :for={tone <- ~w(neutral success warning error)}
            tone={tone}
            label={String.capitalize(tone)}
          />
        </A.cluster>
      <% :stack -> %>
        <A.stack>
          <p>First item</p><p>Second item</p><p>Third item</p>
        </A.stack>
      <% :cluster -> %>
        <A.cluster><A.status :for={number <- 1..8} label={"Item #{number}"} /></A.cluster>
      <% :grid -> %>
        <A.grid>
          <p :for={number <- 1..6}>Cell {number}</p>
        </A.grid>
      <% :split -> %>
        <A.split>
          <p>Main region</p><:secondary>
            <p>Secondary region</p>
          </:secondary>
        </A.split>
      <% :field -> %>
        <.form
          for={@state.form}
          id="sample-form"
          phx-change="example:validate"
          phx-submit="example:save"
        >
          <A.stack>
            <A.field field={@state.form[:name]} label="Name" hint="The name people will see." />
            <A.field
              field={@state.form[:size]}
              type="select"
              label="Size"
              prompt="Choose a size"
              options={[{"Small", "s"}, {"Large", "l"}]}
            />
            <A.field field={@state.form[:notes]} type="textarea" label="Notes" />
            <A.field field={@state.form[:accepted]} type="checkbox" label="Accept terms" />
            <A.field id="example-error" label="Invalid example" value="" errors={["Enter a value."]} />
            <A.field id="example-disabled" label="Disabled example" value="Fixed" disabled />
            <A.button type="submit">Save</A.button>
            <A.notice :if={@state.saved} id="example-saved" tone="success" result>
              Saved for this preview.
            </A.notice>
          </A.stack>
        </.form>
      <% :notice -> %>
        <A.stack>
          <A.notice id="example-static" title="Information">
            Static guidance has no live region.
          </A.notice>
          <A.notice id="example-result" tone="success" result title="Saved">
            Announced politely.
          </A.notice>
          <A.notice id="example-warning" tone="warning" title="Review">
            Check your example values.
          </A.notice>
          <A.notice id="example-failure" tone="error" result title="Could not save">
            An error result is an alert.
          </A.notice>
        </A.stack>
      <% :data_table -> %>
        <A.data_table
          id="example-table"
          rows={@state.records.rows}
          caption="Synthetic records"
          sort_by={@state.sort_by}
          sort_direction={@state.sort_direction}
          sort_event="record_sort"
          select_event="record_select"
          selected_id={@state.selected_id}
          inspector_id="example-details"
        >
          <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
          <:col :let={row} label="Score" numeric sort_key="score">{row.score}</:col>
        </A.data_table>
        <A.inspector id="example-details" title="Selected record">
          <.details state={@state} />
        </A.inspector>
        <A.data_table id="example-empty-table" rows={[]} caption="Empty records">
          <:col label="Name" />
        </A.data_table>
      <% :table_toolbar -> %>
        <A.table_toolbar
          id="example-toolbar"
          query={@state.query}
          total={@state.records.total}
          search_event="record_search"
        >
          <:actions><A.button phx-click="example:action">Add example</A.button></:actions>
        </A.table_toolbar>
        <p role="status">Added {@state.count} examples.</p>
      <% :pagination -> %>
        <A.pagination
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
      <% :inspector -> %>
        <A.button phx-click="record_select" phx-value-id="R-001">Inspect R-001</A.button>
        <A.inspector id="example-inspector" title="Example details">
          <.details state={@state} />
        </A.inspector>
      <% :record_header -> %>
        <A.record_header id="example-header" title="Example record" context="R-001" status="Available">
          <:actions><A.button phx-click="example:action">Review</A.button></:actions>
        </A.record_header>
        <p role="status">Reviewed {@state.count} times.</p>
      <% :table_inspector -> %>
        <A.table_inspector
          id="example-records"
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
          <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
          <:col :let={row} label="Score" numeric sort_key="score">{row.score}</:col>
          <:details><.details state={@state} /></:details>
        </A.table_inspector>
    <% end %>
    """
  end

  attr(:state, :map, required: true)

  defp details(assigns) do
    ~H"""
    <%= if @state.selected do %>
      <A.record_header
        id="example-selected-record"
        title={@state.selected.name}
        context={@state.selected.id}
        status="Available"
      />
      <p>{@state.selected.group}</p><p>Score: {@state.selected.score}</p>
      <p :if={!Enum.any?(@state.records.rows, &(&1.id == @state.selected_id))}>
        The selected record is outside the current results.
      </p>
    <% else %>
      <p>Select a record to see its details.</p>
    <% end %>
    """
  end
end
