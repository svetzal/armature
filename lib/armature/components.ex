defmodule Armature.Components do
  @moduledoc """
  Accessible baseline atoms, layouts, molecules and data compositions.

  Import this module in consumer HTML helpers. Styling comes from
  `priv/static/armature.css` and the consumer's token values. Give standalone
  controls a visible label or an accessible name; `field/1` supplies a label
  and validation relationships for form controls.
  """
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]

  @doc "A native button with a primary or secondary treatment and a visible name."
  attr(:type, :string, default: "button", values: ~w(button submit reset))
  attr(:variant, :string, default: "primary", values: ~w(primary secondary))
  attr(:disabled, :boolean, default: false)
  attr(:rest, :global, include: ~w(form name value))
  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      disabled={@disabled}
      class={["armature-button", "armature-button-#{@variant}"]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "A named link using Phoenix navigation, patching or an ordinary href."
  attr(:navigate, :string, default: nil)
  attr(:patch, :string, default: nil)
  attr(:href, :any, default: nil)
  attr(:replace, :boolean, default: false)
  attr(:method, :string, default: "get")
  attr(:rest, :global, include: ~w(download hreflang referrerpolicy rel target type))
  slot(:inner_block, required: true)

  def link(assigns) do
    ~H"""
    <Phoenix.Component.link
      navigate={@navigate}
      patch={@patch}
      href={@href}
      replace={@replace}
      method={@method}
      class={["armature-link"]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </Phoenix.Component.link>
    """
  end

  @doc "Wraps a consumer's inline SVG as decoration. Put the accessible name on the control."
  slot(:inner_block, required: true)

  def icon(assigns) do
    ~H"""
    <span class={["armature-icon"]} aria-hidden="true">{render_slot(@inner_block)}</span>
    """
  end

  @doc "A native input. Supply a label association or aria-label when used alone."
  attr(:id, :string, required: true)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text")

  attr(:rest, :global,
    include:
      ~w(accept autocomplete capture checked disabled form list max maxlength min minlength multiple pattern placeholder readonly required size step)
  )

  def input(assigns) do
    ~H"""
    <input
      id={@id}
      name={@name}
      type={@type}
      value={
        if(@type == "checkbox", do: @value, else: Phoenix.HTML.Form.normalize_value(@type, @value))
      }
      class={["armature-input"]}
      {@rest}
    />
    """
  end

  @doc "A native select with options and an optional empty prompt. Supply a label when used alone."
  attr(:id, :string, required: true)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:prompt, :string, default: nil)
  attr(:multiple, :boolean, default: false)
  attr(:rest, :global, include: ~w(autocomplete disabled form required size))

  def select(assigns) do
    ~H"""
    <select id={@id} name={@name} multiple={@multiple} class={["armature-select"]} {@rest}>
      <option :if={@prompt} value="">{@prompt}</option>
      {Phoenix.HTML.Form.options_for_select(@options, @value)}
    </select>
    """
  end

  @doc "A native multiline text control. Supply a label association or aria-label when used alone."
  attr(:id, :string, required: true)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)

  attr(:rest, :global,
    include:
      ~w(autocomplete cols disabled form maxlength minlength placeholder readonly required rows wrap)
  )

  def textarea(assigns) do
    ~H"""
    <textarea id={@id} name={@name} class={["armature-textarea"]} {@rest}>{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
    """
  end

  @doc "A compact status badge. Its label must express the meaning independently of its tone."
  attr(:label, :string, required: true)
  attr(:tone, :string, default: "neutral", values: ~w(neutral success warning error))
  attr(:rest, :global)

  def status(assigns) do
    ~H"""
    <span class={["armature-status", "armature-tone-#{@tone}"]} {@rest}>{@label}</span>
    """
  end

  @doc """
  A visible label, native control, hint and validation messages bound by stable ids.

  Use `field={@form[:name]}` or supply `id`, `name` and `value`. FormField errors
  appear only after Phoenix considers the input used. `translate_error` accepts
  each FormField error tuple and returns text; the default uses its message.
  Plain `errors` are already translated strings. `type` selects an input type,
  `select` or `textarea`. Multiple selects append `[]` to FormField names.
  Caller `aria-describedby` ids are preserved; their elements belong to the caller.
  """
  attr(:field, Phoenix.HTML.FormField, default: nil)
  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:label, :string, required: true)
  attr(:type, :string, default: "text")
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: [])
  attr(:translate_error, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:prompt, :string, default: nil)
  attr(:multiple, :boolean, default: false)

  attr(:rest, :global,
    include:
      ~w(accept autocomplete capture checked cols disabled form list max maxlength min minlength pattern placeholder readonly required rows size step)
  )

  def field(assigns) do
    assigns = prepare_field(assigns)

    ~H"""
    <div class={["armature-field"]}>
      <label :if={@type != "checkbox"} for={@id} class={["armature-label"]}>{@label}</label>
      <%= case @type do %>
        <% "select" -> %>
          <.select
            id={@id}
            name={@name}
            value={@value}
            options={@options}
            prompt={@prompt}
            multiple={@multiple}
            {@control_rest}
          />
        <% "textarea" -> %>
          <.textarea id={@id} name={@name} value={@value} {@control_rest} />
        <% "checkbox" -> %>
          <%!-- A checkbox sits before its label, and the row is the touch target.
               An unchecked box submits nothing; the hidden input sends "false". --%>
          <div class={["armature-check"]}>
            <input
              type="hidden"
              name={@name}
              value="false"
              disabled={@control_rest[:disabled]}
              form={@control_rest[:form]}
            />
            <.input
              id={@id}
              name={@name}
              value="true"
              type="checkbox"
              checked={@checked}
              {@control_rest}
            />
            <label for={@id} class={["armature-label"]}>{@label}</label>
          </div>
        <% _ -> %>
          <.input id={@id} name={@name} value={@value} type={@type} {@control_rest} />
      <% end %>
      <p :if={@hint} id={@id <> "-hint"} class={["armature-hint"]}>{@hint}</p>
      <div :if={@errors != []} id={@id <> "-errors"} class={["armature-errors"]}>
        <p :for={error <- @errors}>{error}</p>
      </div>
    </div>
    """
  end

  @doc """
  Feedback with optional title and actions. Set `result` for a reported result:
  non-error results use a polite status region and errors use an alert. Static
  information has no live-region role, including static error guidance.
  """
  attr(:id, :string, required: true)
  attr(:tone, :string, default: "neutral", values: ~w(neutral success warning error))
  attr(:result, :boolean, default: false)
  attr(:title, :string, default: nil)
  slot(:inner_block, required: true)
  slot(:actions)

  def notice(assigns) do
    ~H"""
    <div
      id={@id}
      class={["armature-notice", "armature-tone-#{@tone}"]}
      role={@result && if(@tone == "error", do: "alert", else: "status")}
      aria-atomic={@result && "true"}
    >
      <p :if={@title} class={["armature-notice-title"]}>{@title}</p>
      <div>{render_slot(@inner_block)}</div>
      <div :if={@actions != []} class={["armature-notice-actions"]}>{render_slot(@actions)}</div>
    </div>
    """
  end

  @doc "Arranges children vertically with consistent spacing and no added meaning."
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def stack(assigns) do
    ~H"""
    <div class={["armature-stack"]} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "Arranges an inline group that wraps when space runs out."
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def cluster(assigns) do
    ~H"""
    <div class={["armature-cluster"]} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "Arranges responsive columns using the layout-min-width token."
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def grid(assigns) do
    ~H"""
    <div class={["armature-grid"]} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  @doc "Arranges two regions side by side, stacking them when their minimum widths no longer fit."
  attr(:rest, :global)
  slot(:inner_block, required: true)
  slot(:secondary, required: true)

  def split(assigns) do
    ~H"""
    <div class={["armature-split"]} {@rest}>
      <div>{render_slot(@inner_block)}</div>
      <div>{render_slot(@secondary)}</div>
    </div>
    """
  end

  @doc """
  A native table with scoped headings and caller-owned ordering and selection.

  Columns render each row through `:let`; `sort_key` buttons send `key` to
  `sort_event`. Selection buttons send `id` to `select_event`. Supply an existing
  `inspector_id` when enabling selection. Row identifiers must be unique and DOM-safe.
  `caption_hidden` hides only the caption visually. Empty results use words.
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:caption, :string, required: true)
  attr(:caption_hidden, :boolean, default: false)
  attr(:empty_label, :string, default: "No records to display.")
  attr(:striped, :boolean, default: true)
  attr(:sort_by, :string, default: nil)
  attr(:sort_direction, :string, default: "asc", values: ~w(asc desc))
  attr(:sort_event, :string, default: nil)
  attr(:row_id, :any, default: nil)
  attr(:select_event, :string, default: nil)
  attr(:selected_id, :any, default: nil)
  attr(:inspector_id, :string, default: nil)

  slot :col, required: true do
    attr(:label, :string, required: true)
    attr(:numeric, :boolean)
    attr(:sort_key, :string)
  end

  def data_table(assigns) do
    if assigns.select_event && !assigns.inspector_id do
      raise ArgumentError, "selection requires an existing inspector_id"
    end

    assigns = assign(assigns, :row_id, assigns.row_id || (&Map.fetch!(&1, :id)))

    ~H"""
    <div
      id={@id <> "-scroll"}
      class={["armature-table-scroll"]}
      tabindex="0"
      role="region"
      aria-label={@caption}
    >
      <p :if={@rows == []} id={@id <> "-empty"} class={["armature-table-empty"]}>{@empty_label}</p>
      <table
        :if={@rows != []}
        id={@id}
        class={["armature-table", @striped && "armature-table-striped"]}
      >
        <caption class={[@caption_hidden && "armature-sr-only"]}>{@caption}</caption>
        <thead>
          <tr>
            <th :if={@select_event} scope="col">Selection</th>
            <th
              :for={col <- @col}
              scope="col"
              class={[col[:numeric] && "armature-numeric"]}
              aria-sort={
                if(@sort_event && col[:sort_key] && @sort_by == col[:sort_key],
                  do: sort_description(@sort_direction)
                )
              }
            >
              <button
                :if={@sort_event && col[:sort_key]}
                type="button"
                class={["armature-sort"]}
                phx-click={@sort_event}
                phx-value-key={col.sort_key}
                aria-label={"Sort by #{col.label}"}
              >
                {col.label}<span :if={@sort_by == col.sort_key} aria-hidden="true">{if(
                  @sort_direction == "asc",
                  do: " ↑",
                  else: " ↓"
                )}</span><span
                  :if={@sort_by != col.sort_key}
                  class={["armature-sort-hint"]}
                  aria-hidden="true"
                > ↕</span>
              </button>
              <span :if={!@sort_event || !col[:sort_key]}>{col.label}</span>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={row <- @rows}
            id={@id <> "-" <> to_string(@row_id.(row))}
            class={[@select_event && @selected_id == @row_id.(row) && "armature-row-selected"]}
          >
            <td :if={@select_event}>
              <button
                type="button"
                class={["armature-row-select"]}
                phx-click={@select_event}
                phx-value-id={@row_id.(row)}
                aria-label={"Select #{@row_id.(row)}"}
                aria-pressed={to_string(@selected_id == @row_id.(row))}
                aria-controls={@inspector_id}
              >
                {if(@selected_id == @row_id.(row), do: "Selected", else: "Select")}
              </button>
            </td>
            <td :for={col <- @col} class={[col[:numeric] && "armature-numeric"]}>
              {render_slot(col, row)}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc "A labelled search form, polite atomic result count and optional caller actions. Sends query."
  attr(:id, :string, required: true)
  attr(:search_label, :string, default: "Search records")
  attr(:search_event, :string, required: true)
  attr(:query, :string, default: "")
  attr(:total, :integer, required: true)
  slot(:actions)

  def table_toolbar(assigns) do
    ~H"""
    <div id={@id} class={["armature-table-toolbar"]}>
      <form id={@id <> "-search-form"} phx-change={@search_event} phx-submit={@search_event}>
        <label for={@id <> "-search"}>{@search_label}</label>
        <.input id={@id <> "-search"} type="search" name="query" value={@query} />
      </form>
      <span id={@id <> "-count"} role="status" aria-live="polite" aria-atomic="true">{format_count(
        @total
      )} results</span>
      <div :if={@actions != []} class={["armature-toolbar-actions"]}>{render_slot(@actions)}</div>
    </div>
    """
  end

  @doc """
  Named page controls and a polite atomic range announcement. The caller owns page state.

  Send `page` to `page_event`. Use page 1 of 1 and range 0–0 for no results.
  Supplying `page_sizes` and `size_event` adds a labelled select sending `page_size`.
  """
  attr(:id, :string, required: true)
  attr(:page, :integer, required: true)
  attr(:pages, :integer, required: true)
  attr(:first, :integer, required: true)
  attr(:last, :integer, required: true)
  attr(:total, :integer, required: true)
  attr(:page_event, :string, required: true)
  attr(:page_size, :integer, default: 25)
  attr(:page_sizes, :list, default: [])
  attr(:size_event, :string, default: nil)

  def pagination(assigns) do
    ~H"""
    <nav id={@id} class={["armature-pagination"]} aria-label="Table pages">
      <span id={@id <> "-range"} role="status" aria-live="polite" aria-atomic="true">{format_count(
        @first
      )}–{format_count(@last)} of {format_count(@total)}</span>
      <form
        :if={@page_sizes != [] && @size_event}
        id={@id <> "-size-form"}
        phx-change={@size_event}
        phx-submit={@size_event}
      >
        <label for={@id <> "-size"}>Records per page</label>
        <.select id={@id <> "-size"} name="page_size" value={@page_size} options={@page_sizes} />
      </form>
      <.button
        variant="secondary"
        phx-click={@page_event}
        phx-value-page={max(1, @page - 1)}
        disabled={@page <= 1}
        aria-label="Previous page"
      >Previous</.button>
      <.button
        variant="secondary"
        phx-click={@page_event}
        phx-value-page={min(@pages, @page + 1)}
        disabled={@page >= @pages}
        aria-label="Next page"
      >Next</.button>
    </nav>
    """
  end

  @doc "A complementary landmark named by its heading. Link to its id to skip to details; never a live region."
  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  slot(:inner_block, required: true)

  def inspector(assigns) do
    ~H"""
    <aside id={@id} class={["armature-inspector"]} aria-labelledby={@id <> "-heading"} tabindex="-1">
      <h2 id={@id <> "-heading"}>{@title}</h2>
      {render_slot(@inner_block)}
    </aside>
    """
  end

  @doc "A record heading, optional context and status in words, and caller actions."
  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:context, :string, default: nil)
  attr(:status, :string, default: nil)
  slot(:actions)

  def record_header(assigns) do
    ~H"""
    <header id={@id} class={["armature-record-header"]}>
      <div>
        <h2 id={@id <> "-heading"}>{@title}</h2>
        <p :if={@context}>{@context}</p>
        <.status :if={@status} label={@status} />
      </div>
      <div :if={@actions != []} class={["armature-record-actions"]}>{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  A table-and-details template composing the complete data browsing workflow.

  The caller owns filtering, ordering, paging and persistent selection. Columns
  receive each row; `details` holds the selected record's content. Update
  `selection_label` on selection changes to announce them without moving focus.
  The skip link targets the inspector; narrow layouts place it below the table.
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:caption, :string, required: true)
  attr(:query, :string, default: "")
  attr(:search_event, :string, required: true)
  attr(:sort_event, :string, required: true)
  attr(:sort_by, :string, default: nil)
  attr(:sort_direction, :string, default: "asc", values: ~w(asc desc))
  attr(:row_id, :any, default: nil)
  attr(:select_event, :string, required: true)
  attr(:selected_id, :any, default: nil)
  attr(:selection_label, :string, default: "No record selected.")
  attr(:inspector_title, :string, default: "Record details")
  attr(:page, :integer, required: true)
  attr(:pages, :integer, required: true)
  attr(:first, :integer, required: true)
  attr(:last, :integer, required: true)
  attr(:total, :integer, required: true)
  attr(:page_event, :string, required: true)
  attr(:page_size, :integer, default: 25)
  attr(:page_sizes, :list, default: [])
  attr(:size_event, :string, default: nil)

  slot :col, required: true do
    attr(:label, :string, required: true)
    attr(:numeric, :boolean)
    attr(:sort_key, :string)
  end

  slot(:actions)
  slot(:details, required: true)

  def table_inspector(assigns) do
    ~H"""
    <div id={@id} class={["armature-table-inspector"]}>
      <.link href={"##{@id}-inspector"}>Skip to {@inspector_title}</.link>
      <p
        id={@id <> "-selection"}
        class={["armature-sr-only"]}
        role="status"
        aria-live="polite"
        aria-atomic="true"
      >
        {@selection_label}
      </p>
      <.split>
        <.table_toolbar
          id={@id <> "-toolbar"}
          search_event={@search_event}
          query={@query}
          total={@total}
        >
          <:actions>{render_slot(@actions)}</:actions>
        </.table_toolbar>
        <.data_table
          id={@id <> "-table"}
          rows={@rows}
          caption={@caption}
          sort_by={@sort_by}
          sort_direction={@sort_direction}
          sort_event={@sort_event}
          row_id={@row_id}
          select_event={@select_event}
          selected_id={@selected_id}
          inspector_id={@id <> "-inspector"}
        >
          <:col
            :let={row}
            :for={col <- @col}
            label={col.label}
            numeric={col[:numeric] || false}
            sort_key={col[:sort_key]}
          >
            {render_slot(col, row)}
          </:col>
        </.data_table>
        <.pagination
          id={@id <> "-pagination"}
          page={@page}
          pages={@pages}
          first={@first}
          last={@last}
          total={@total}
          page_event={@page_event}
          page_size={@page_size}
          page_sizes={@page_sizes}
          size_event={@size_event}
        />
        <:secondary>
          <.inspector id={@id <> "-inspector"} title={@inspector_title}>
            {render_slot(@details)}
          </.inspector>
        </:secondary>
      </.split>
    </div>
    """
  end

  defp prepare_field(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    translator = assigns.translate_error || fn {message, _options} -> message end
    errors = if used_input?(field), do: Enum.map(field.errors, translator), else: []
    name = field.name <> if(assigns.multiple, do: "[]", else: "")

    assigns
    |> assign(
      field: nil,
      id: assigns.id || field.id,
      name: assigns.name || name,
      value: if(is_nil(assigns.value), do: field.value, else: assigns.value),
      errors: errors
    )
    |> prepare_field()
  end

  defp prepare_field(%{id: nil}) do
    raise ArgumentError, "field requires an id when no FormField is supplied"
  end

  defp prepare_field(assigns) do
    descriptions =
      [
        assigns.rest[:"aria-describedby"],
        assigns.hint && assigns.id <> "-hint",
        assigns.errors != [] && assigns.id <> "-errors"
      ]
      |> Enum.filter(& &1)
      |> Enum.flat_map(&String.split/1)
      |> Enum.uniq()
      |> Enum.join(" ")

    rest =
      assigns.rest
      |> Map.delete(:"aria-invalid")
      |> Map.delete(:checked)
      |> Map.put(:"aria-describedby", if(descriptions == "", do: nil, else: descriptions))
      |> Map.put(:"aria-invalid", if(assigns.errors != [], do: "true", else: nil))

    # A caller's explicit `checked` wins; otherwise the bound value decides.
    checked =
      Map.get_lazy(assigns.rest, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns.value)
      end)

    assign(assigns, control_rest: rest, checked: checked)
  end

  defp sort_description("asc"), do: "ascending"
  defp sort_description("desc"), do: "descending"

  defp format_count(count) do
    count |> Integer.to_string() |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
  end
end
