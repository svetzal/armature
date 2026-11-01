defmodule Armature.Components.Organisms do
  @moduledoc """
  Baseline organisms: complete regions such as navigation, panels, tables and
  inspectors, composed from atoms, layouts and molecules.
  """
  use Phoenix.Component

  alias Armature.Components.Atoms
  alias Armature.Components.Attributes
  alias Armature.Components.Layouts

  @column_attributes Attributes.columns()

  @doc """
  A named navigation landmark with an optional brand, section links and footnote.

  Each item has `:label` and one of `:href`, `:patch` or `:navigate`, with optional
  `:id` and `:current`. `label` names the navigation landmark; it defaults to
  "Main", so give a second rail on the same page its own name. `title` and
  `subtitle` form the brand, and `section_label` adds a caption above the links.
  Each renders only when given. Optional `home_patch` links the wordmark to an
  index. The optional `mark` slot puts a logo or symbol, such as an `<img>` or
  an inline SVG, on the same row before the title and inside its link. It
  renders only with a title, which names the brand, so the mark is hidden from
  assistive technology. Its height is `--armature-brand-mark-size` and its width
  follows the image's aspect ratio. The caller owns the current page. The rail
  becomes a wrapping row on small screens; its subtitle, caption and footnote
  then hide.
  """
  attr(:id, :string, required: true)
  attr(:title, :string, default: nil)
  attr(:subtitle, :string, default: nil)
  attr(:label, :string, default: "Main")
  attr(:section_label, :string, default: nil)
  attr(:home_patch, :string, default: nil)
  attr(:items, :list, required: true)
  slot(:mark)
  slot(:footnote)

  def side_nav(assigns) do
    ~H"""
    <div id={@id} class={["armature-side-nav"]}>
      <div :if={@title || @subtitle} class={["armature-side-nav-brand"]}>
        <Atoms.link :if={@title && @home_patch} patch={@home_patch} aria-label={@title <> " home"}>
          <.brand_mark mark={@mark} />{@title}
        </Atoms.link>
        <span :if={@title && !@home_patch}><.brand_mark mark={@mark} />{@title}</span>
        <small :if={@subtitle}>{@subtitle}</small>
      </div>
      <Atoms.eyebrow :if={@section_label}>{@section_label}</Atoms.eyebrow>
      <nav aria-label={@label}>
        <.nav_links items={@items} />
      </nav>
      <div :if={@footnote != []} class={["armature-side-nav-footnote"]}>{render_slot(@footnote)}</div>
    </div>
    """
  end

  attr(:mark, :list, required: true)

  defp brand_mark(assigns) do
    ~H"""
    <span :if={@mark != []} class={["armature-side-nav-mark"]} aria-hidden="true">{render_slot(@mark)}</span>
    """
  end

  @doc "A context band with an optional actions slot. The context is a visible brand path."
  attr(:context, :string, required: true)
  slot(:actions)

  def top_bar(assigns) do
    ~H"""
    <header class={["armature-top-bar"]} aria-label={@context}>
      <Layouts.cluster>
        <span>{@context}</span><div>{render_slot(@actions)}</div>
      </Layouts.cluster>
    </header>
    """
  end

  @doc """
  Grouped navigation links with a labelled native select on narrow screens.

  Groups contain `:label` and `:items`; items follow `side_nav/1`'s contract.
  The select submits `destination` to the caller's `event` on change. Validate
  that destination against the supplied items before navigating. The caller
  owns selection and navigation; the component retains no state.
  """
  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:groups, :list, required: true)
  attr(:event, :string, required: true)

  slot(:inner_block)

  def grouped_nav(assigns) do
    assigns =
      assign(assigns,
        picker_options: picker_options(assigns.groups),
        current_destination: current_destination(assigns.groups)
      )

    ~H"""
    <div id={@id} class={["armature-grouped-nav"]}>
      <nav aria-label={@label} class={["armature-grouped-nav-links"]}>
        <section :for={group <- @groups} data-level={Map.get(group, :level)}>
          <Atoms.eyebrow>{group.label}</Atoms.eyebrow>
          <.nav_links items={group.items} />
        </section>
      </nav>
      <form
        id={@id <> "-form"}
        class={["armature-grouped-nav-picker"]}
        phx-change={@event}
        phx-submit={@event}
      >
        <label for={@id <> "-choice"}>{@label}</label>
        <Atoms.select
          id={@id <> "-choice"}
          name="destination"
          prompt="Choose a component"
          value={@current_destination}
          options={@picker_options}
          aria-describedby={@id <> "-hint"}
        />
        <p id={@id <> "-hint"}>Choosing an option opens its page.</p>
      </form>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A named paper-surface region with an h2, optional actions and caller-owned content.
  Place panels in `grid/1` for responsive tiling. Use notices and status labels in
  the content to express loading, empty, invalid or error states in words.
  """
  attr(:id, :string, required: true)
  attr(:heading, :string, required: true)
  attr(:rest, :global)
  slot(:actions)
  slot(:inner_block, required: true)

  def panel(assigns) do
    ~H"""
    <section id={@id} class={["armature-panel"]} aria-labelledby={@id <> "-heading"} {@rest}>
      <Layouts.cluster>
        <h2 id={@id <> "-heading"}>{@heading}</h2>
        <div :if={@actions != []}>{render_slot(@actions)}</div>
      </Layouts.cluster>
      {render_slot(@inner_block)}
    </section>
    """
  end

  @doc """
  A native table with scoped headings and caller-owned ordering and selection.

  Columns render each row through `:let`; `sort_key` buttons send `key` to
  `sort_event`. Mark exactly one column `row_label` to render its visible content
  as the selection button, sending `id` to `select_event`. Supply an existing
  `inspector_id` when enabling selection. `row_id` returns a row's identifier;
  without it, rows that all have an `:id` use it. Selection requires one or the
  other and raises an error otherwise. A table without selection needs neither:
  its rows then take DOM ids from their position. Identifiers must be unique and DOM-safe.
  A selectable row contains exactly one interactive element: its row-label button.
  Other column content must be non-interactive; declared `interactive` columns
  raise an error. For additional actions use a non-selectable table with explicit
  links or a details pattern. Selection also works by clicking anywhere on the row.
  `density="compact"` reduces cell padding and row height on fine pointers.
  `caption_hidden` hides only the caption visually. Empty results use words.
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:caption, :string, required: true)
  attr(:density, :string, default: "default", values: ~w(default compact))
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
    for {name, type, opts} <- @column_attributes, do: attr(name, type, opts)
  end

  def data_table(assigns) do
    if assigns.select_event && !assigns.inspector_id do
      raise ArgumentError, "selection requires an existing inspector_id"
    end

    validate_selectable_columns!(assigns)
    assigns = assign_row_identity(assigns)

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
        data-density={@density}
      >
        <caption class={[@caption_hidden && "armature-sr-only"]}>{@caption}</caption>
        <thead>
          <tr>
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
            :for={{row, index} <- Enum.with_index(@rows)}
            id={@id <> "-" <> to_string(@row_key.(row, index))}
            class={[
              @select_event && "armature-clickable-row",
              @select_event && @selected_id == @row_id.(row) && "armature-row-selected"
            ]}
            phx-click={@select_event}
            phx-value-id={@select_event && @row_id.(row)}
          >
            <td :for={col <- @col} class={[col[:numeric] && "armature-numeric"]}>
              <%= if @select_event && col[:row_label] do %>
                <button
                  type="button"
                  class={["armature-row-select"]}
                  phx-click={@select_event}
                  phx-value-id={@row_id.(row)}
                  aria-pressed={to_string(@selected_id == @row_id.(row))}
                  aria-controls={@inspector_id}
                >
                  {render_slot(col, row)}
                </button>
              <% else %>
                {render_slot(col, row)}
              <% end %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
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

  attr(:items, :list, required: true)

  defp nav_links(assigns) do
    ~H"""
    <Atoms.link
      :for={item <- @items}
      id={Map.get(item, :id)}
      href={Map.get(item, :href)}
      patch={Map.get(item, :patch)}
      navigate={Map.get(item, :navigate)}
      aria-current={if Map.get(item, :current), do: "page"}
    >
      {item.label}
    </Atoms.link>
    """
  end

  defp picker_options(groups) do
    Enum.map(groups, fn group ->
      {group.label, Enum.map(group.items, &{&1.label, destination(&1)})}
    end)
  end

  defp current_destination(groups) do
    groups
    |> Enum.flat_map(& &1.items)
    |> Enum.find_value(&(Map.get(&1, :current) && destination(&1)))
  end

  defp destination(item) do
    Map.get(item, :patch) || Map.get(item, :navigate) || Map.get(item, :href)
  end

  # Selection needs an identifier per row; plain tables only need distinct DOM
  # ids, so rows without one fall back to their position in this render.
  defp assign_row_identity(%{row_id: row_id} = assigns) when is_function(row_id, 1),
    do: assign(assigns, row_key: fn row, _index -> row_id.(row) end)

  defp assign_row_identity(assigns) do
    cond do
      Enum.all?(assigns.rows, &(is_map(&1) and Map.has_key?(&1, :id))) ->
        assign(assigns, row_id: & &1.id, row_key: fn row, _index -> row.id end)

      assigns.select_event ->
        raise ArgumentError,
              "selectable tables need a row identifier: pass row_id, or give every row an :id"

      true ->
        assign(assigns, row_key: fn _row, index -> "row-#{index}" end)
    end
  end

  defp validate_selectable_columns!(%{select_event: nil}), do: :ok

  defp validate_selectable_columns!(assigns) do
    if Enum.count(assigns.col, & &1[:row_label]) != 1 do
      raise ArgumentError, "selectable tables require exactly one row_label column"
    end

    if Enum.any?(assigns.col, & &1[:interactive]) do
      raise ArgumentError,
            "selectable rows allow only the row-label button; use a non-selectable table for actions"
    end
  end

  defp sort_description("asc"), do: "ascending"
  defp sort_description("desc"), do: "descending"
end
