defmodule Armature.Components.Templates do
  @moduledoc """
  Baseline templates: whole-page and whole-workflow arrangements of organisms,
  molecules, layouts and atoms. The caller owns every piece of state.
  """
  use Phoenix.Component

  alias Armature.Components.Atoms
  alias Armature.Components.Attributes
  alias Armature.Components.Layouts
  alias Armature.Components.Molecules
  alias Armature.Components.Organisms

  @column_attributes Attributes.columns()
  @paging_attributes Attributes.paging()

  @doc """
  An application shell with a skip link, side navigation, context bar and page heading.
  Supply globally unique `id` and `heading_id`. Item navigation and theme state
  belong to the consumer. `title`, `subtitle`, `nav_label` and `section_label`
  pass to `side_nav/1`, which renders a brand and caption only when given.
  The optional `mark` slot passes to `side_nav/1`'s `mark`, a decorative logo
  or symbol before the title.
  The rail narrows below 800px and stacks below 520px of the shell's own inline size.

  The skip link is an ordinary `href` fragment to the h1, which has
  `tabindex="-1"`, so it moves focus on pages without LiveView. Its
  `JS.focus/1` command is an enhancement for LiveView pages. `heading_rest`
  forwards LiveView focus commands to the h1 after patch navigation.
  """
  attr(:id, :string, required: true)
  attr(:title, :string, default: nil)
  attr(:subtitle, :string, default: nil)
  attr(:nav_label, :string, default: "Main")
  attr(:section_label, :string, default: nil)
  attr(:items, :list, required: true)
  attr(:context, :string, required: true)
  attr(:heading, :string, required: true)
  attr(:heading_id, :string, required: true)
  attr(:heading_rest, :map, default: %{})
  attr(:home_patch, :string, default: nil)
  attr(:eyebrow, :string, default: nil)
  attr(:rest, :global)
  slot(:mark)
  slot(:footnote)
  slot(:top_actions)
  slot(:heading_actions)
  slot(:inner_block, required: true)

  def app_shell(assigns) do
    ~H"""
    <div id={@id} class={["armature-app-shell"]} {@rest}>
      <Atoms.link
        href={"#" <> @heading_id}
        class={["armature-skip-link"]}
        phx-click={Phoenix.LiveView.JS.focus(to: "#" <> @heading_id)}
      >Skip to main content</Atoms.link>
      <div class={["armature-app-shell-grid"]}>
        <Organisms.side_nav
          id={@id <> "-rail"}
          title={@title}
          subtitle={@subtitle}
          label={@nav_label}
          section_label={@section_label}
          home_patch={@home_patch}
          items={@items}
        >
          <:mark :if={@mark != []}>{render_slot(@mark)}</:mark>
          <:footnote :if={@footnote != []}>{render_slot(@footnote)}</:footnote>
        </Organisms.side_nav>
        <div class={["armature-app-shell-main"]}>
          <Organisms.top_bar context={@context}>
            <:actions>{render_slot(@top_actions)}</:actions>
          </Organisms.top_bar>
          <main aria-labelledby={@heading_id}>
            <Molecules.page_heading
              id={@heading_id}
              title={@heading}
              eyebrow={@eyebrow}
              {@heading_rest}
            >
              <:actions>{render_slot(@heading_actions)}</:actions>
            </Molecules.page_heading>
            <div class={["armature-app-shell-content"]}>{render_slot(@inner_block)}</div>
          </main>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  A table-and-details template composing the complete data browsing workflow.

  The caller owns filtering, ordering, paging and persistent selection. `col`
  slots are forwarded unchanged to `data_table/1`, which defines their contract,
  and the paging attributes follow `pagination/1`. `details` holds
  the selected record's content. Update
  `selection_label` on selection changes to announce them without moving focus.
  The skip link targets the inspector; narrow layouts place it below the table.
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:caption, :string, required: true)
  attr(:density, :string, default: "default", values: ~w(default compact))
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
  for {name, type, opts} <- @paging_attributes, do: attr(name, type, opts)

  slot :col, required: true do
    for {name, type, opts} <- @column_attributes, do: attr(name, type, opts)
  end

  slot(:actions)
  slot(:details, required: true)

  def table_inspector(assigns) do
    ~H"""
    <div id={@id} class={["armature-table-inspector"]}>
      <Atoms.link href={"##{@id}-inspector"}>Skip to {@inspector_title}</Atoms.link>
      <p
        id={@id <> "-selection"}
        class={["armature-sr-only"]}
        role="status"
        aria-live="polite"
        aria-atomic="true"
      >
        {@selection_label}
      </p>
      <Layouts.split>
        <Molecules.table_toolbar
          id={@id <> "-toolbar"}
          search_event={@search_event}
          query={@query}
          total={@total}
        >
          <:actions>{render_slot(@actions)}</:actions>
        </Molecules.table_toolbar>
        <Organisms.data_table
          id={@id <> "-table"}
          rows={@rows}
          caption={@caption}
          density={@density}
          sort_by={@sort_by}
          sort_direction={@sort_direction}
          sort_event={@sort_event}
          row_id={@row_id}
          select_event={@select_event}
          selected_id={@selected_id}
          inspector_id={@id <> "-inspector"}
        >
          <:col :let={row} :for={col <- @col} {Map.drop(col, [:__slot__, :inner_block])}>
            {render_slot(col, row)}
          </:col>
        </Organisms.data_table>
        <Molecules.pagination
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
          <Organisms.inspector id={@id <> "-inspector"} title={@inspector_title}>
            {render_slot(@details)}
          </Organisms.inspector>
        </:secondary>
      </Layouts.split>
    </div>
    """
  end
end
