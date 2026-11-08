defmodule Armature.Components.Molecules do
  @moduledoc """
  Baseline molecules: small groups of atoms and layouts with one job each,
  such as a labelled field, a notice or paging controls.
  """
  use Phoenix.Component

  alias Armature.Components.Atoms
  alias Armature.Components.Attributes
  alias Armature.Components.Layouts

  @tones Attributes.tones()
  @themes Armature.Components.themes()

  # field/1 declares `multiple` itself, so it is not forwarded through `rest`.
  @field_attributes Attributes.controls() -- ~w(multiple)
  @paging_attributes Attributes.paging()

  @doc """
  A page's h1 with an optional contextual eyebrow and actions or status.
  Supply a unique `id` as the skip-link target. `rest` forwards focus commands
  to the focusable heading, so consumers can recover focus after navigation.
  """
  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:eyebrow, :string, default: nil)
  attr(:rest, :global)
  slot(:actions)

  def page_heading(assigns) do
    ~H"""
    <div class={["armature-page-heading"]}>
      <Layouts.cluster>
        <div>
          <Atoms.eyebrow :if={@eyebrow}>{@eyebrow}</Atoms.eyebrow>
          <h1 id={@id} tabindex="-1" {@rest}>{@title}</h1>
        </div>
        <div :if={@actions != []}>{render_slot(@actions)}</div>
      </Layouts.cluster>
    </div>
    """
  end

  @doc """
  A three-way System/Light/Dark pill toggle built from native radios.

  A fieldset whose legend carries `label` (default "Theme") groups three
  radios named `theme` with the values `"auto"`, `"light"` and `"dark"`. Each
  choice shows an icon (a monitor, a sun, a moon) and has a name in words.
  The names are the caller's: `auto_label`, `light_label` and `dark_label`
  (default "System", "Light" and "Dark"). The choices sit in a rounded track. The radio
  that matches `value` is checked, and its choice is a raised thumb: a paper
  surface inside a control border, with a soft shadow and an ink icon.
  Native radios give one tab stop and arrow-key movement. The legend is
  visually hidden unless `label_visible` is true; it still names the group
  for assistive technology.

  In a LiveView, `event` receives `%{"theme" => value}` on change and submit,
  and the consumer applies its chosen theme. `"auto"` follows the system
  preference: the consumer removes the theme attribute to inherit its tokens
  without overwriting them. On a page without a LiveView socket, omit `event`
  and load `armature-theme.js`: it finds the form by its
  `data-armature-theme-switch` attribute, applies and remembers the choice on
  the document element and announces whichever name is rendered. The script leaves alone any switch
  inside a LiveView.
  """
  attr(:id, :string, required: true)
  attr(:value, :string, default: "auto", values: @themes)
  attr(:label, :string, default: "Theme")
  attr(:label_visible, :boolean, default: false)
  attr(:auto_label, :string, default: "System")
  attr(:light_label, :string, default: "Light")
  attr(:dark_label, :string, default: "Dark")
  attr(:event, :string, default: nil)
  slot(:inner_block)

  def theme_switch(assigns) do
    ~H"""
    <form
      id={@id}
      class={["armature-theme-switch"]}
      data-armature-theme-switch
      phx-change={@event}
      phx-submit={@event}
    >
      <fieldset>
        <legend class={[!@label_visible && "armature-sr-only"]}>{@label}</legend>
        <span class={["armature-theme-switch-options"]}>
          <.theme_choice
            id={@id}
            value="auto"
            name={@auto_label}
            icon="monitor"
            checked={@value == "auto"}
          />
          <.theme_choice
            id={@id}
            value="light"
            name={@light_label}
            icon="sun"
            checked={@value == "light"}
          />
          <.theme_choice
            id={@id}
            value="dark"
            name={@dark_label}
            icon="moon"
            checked={@value == "dark"}
          />
        </span>
      </fieldset>
      {render_slot(@inner_block)}
    </form>
    """
  end

  attr(:id, :string, required: true)
  attr(:value, :string, required: true)
  attr(:name, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:checked, :boolean, required: true)

  # The radio covers its whole choice, so the choice is its target; the
  # name in words is the radio's label and the icon is decoration.
  defp theme_choice(assigns) do
    ~H"""
    <label class={["armature-theme-switch-option"]} title={@name}>
      <Atoms.input
        type="radio"
        id={@id <> "-" <> @value}
        name="theme"
        value={@value}
        checked={@checked}
      />
      <Atoms.icon name={@icon} />
      <span class={["armature-sr-only"]}>{@name}</span>
    </label>
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

  attr(:rest, :global, include: @field_attributes)

  def field(assigns) do
    assigns = prepare_field(assigns)

    ~H"""
    <div class={["armature-field"]}>
      <Atoms.label :if={@type != "checkbox"} for={@id}>{@label}</Atoms.label>
      <%= case @type do %>
        <% "select" -> %>
          <Atoms.select
            id={@id}
            name={@name}
            value={@value}
            options={@options}
            prompt={@prompt}
            multiple={@multiple}
            {@control_rest}
          />
        <% "textarea" -> %>
          <Atoms.textarea id={@id} name={@name} value={@value} {@control_rest} />
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
            <Atoms.input
              id={@id}
              name={@name}
              value="true"
              type="checkbox"
              checked={@checked}
              {@control_rest}
            />
            <Atoms.label for={@id}>{@label}</Atoms.label>
          </div>
        <% _ -> %>
          <Atoms.input id={@id} name={@name} value={@value} type={@type} {@control_rest} />
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
  attr(:tone, :string, default: "neutral", values: @tones)
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

  @doc "A description list of labelled facts. Values may contain lower-level components."
  slot :fact, required: true do
    attr(:label, :string, required: true)
  end

  def facts(assigns) do
    ~H"""
    <dl class={["armature-facts"]}>
      <div :for={fact <- @fact}>
        <dt>{fact.label}</dt>
        <dd>{render_slot(fact)}</dd>
      </div>
    </dl>
    """
  end

  @doc """
  A labelled search form, polite atomic result count and optional caller actions. Sends query.

  The words are the caller's: `search_label` labels the search (default
  "Search records"), `clear_label` names the clear button (default "Clear
  search"), and `count_label` is a function from `total` to the count text
  (default "1,234 results"), so a translation controls the word order.
  """
  attr(:id, :string, required: true)
  attr(:search_label, :string, default: "Search records")
  attr(:clear_label, :string, default: "Clear search")
  attr(:count_label, :any, default: nil)
  attr(:search_event, :string, required: true)
  attr(:query, :string, default: "")
  attr(:total, :integer, required: true)
  slot(:actions)

  def table_toolbar(assigns) do
    assigns =
      assign(assigns, :count_label, assigns.count_label || (&default_count_label/1))

    ~H"""
    <div id={@id} class={["armature-table-toolbar"]}>
      <form id={@id <> "-search-form"} phx-change={@search_event} phx-submit={@search_event}>
        <Atoms.label for={@id <> "-search"} visually_hidden>{@search_label}</Atoms.label>
        <div class={["armature-search"]}>
          <Atoms.icon name="search" />
          <Atoms.input id={@id <> "-search"} type="search" name="query" value={@query} />
          <Atoms.button
            :if={@query != ""}
            id={@id <> "-clear"}
            variant="secondary"
            phx-click={@search_event}
            phx-value-query=""
            aria-label={@clear_label}
          >
            <Atoms.icon name="x" />
          </Atoms.button>
        </div>
      </form>
      <span id={@id <> "-count"} role="status" aria-live="polite" aria-atomic="true">{@count_label.(
        @total
      )}</span>
      <div :if={@actions != []} class={["armature-toolbar-actions"]}>{render_slot(@actions)}</div>
    </div>
    """
  end

  @doc """
  A square, icon-only native button with a required name.

  `label` names the button for assistive technology, as visually hidden text
  inside it, and is also its native `title`. Show a vendored glyph with
  `icon` (one of `Armature.Icons.names/0`) or put your own inline SVG in the
  slot. `variant` is `"secondary"` (the default, a paper surface) or
  `"primary"` (an accent fill), as for `Armature.Components.Atoms.button/1`.
  Set `pressed` to `true` or `false` to make a toggle: it renders `aria-pressed`, and a pressed button
  shows a selected surface with a marker bar along its lower edge, so the
  state does not rest on colour. Leave `pressed` unset for an ordinary action.
  The button is square: one compact control tall on a fine pointer, and at
  least 44px under a coarse pointer or a narrow viewport.
  """
  attr(:label, :string, required: true)
  attr(:icon, :string, default: nil, values: [nil | Armature.Icons.names()])
  attr(:type, :string, default: "button", values: ~w(button submit reset))
  attr(:variant, :string, default: "secondary", values: ~w(primary secondary))
  attr(:disabled, :boolean, default: false)
  attr(:pressed, :boolean, default: nil)
  attr(:rest, :global, include: ~w(form name value))
  slot(:inner_block)

  def icon_button(%{icon: nil, inner_block: []}) do
    raise ArgumentError, "icon_button needs an icon name or an inline SVG in its slot"
  end

  def icon_button(%{icon: icon, inner_block: [_ | _]}) when is_binary(icon) do
    raise ArgumentError, "icon_button takes an icon name or an inline SVG, not both"
  end

  def icon_button(assigns) do
    ~H"""
    <Atoms.button
      type={@type}
      variant={@variant}
      disabled={@disabled}
      title={@label}
      aria-pressed={if(is_boolean(@pressed), do: to_string(@pressed))}
      data-armature-icon-button
      {@rest}
    >
      <Atoms.icon :if={@icon} name={@icon} />
      <Atoms.icon :if={!@icon}>{render_slot(@inner_block)}</Atoms.icon>
      <span class={["armature-sr-only"]}>{@label}</span>
    </Atoms.button>
    """
  end

  @doc """
  A named group of controls with one tab stop, following the ARIA toolbar pattern.

  Each `group` slot holds related controls, such as `icon_button/1` and
  `Armature.Components.Atoms.button/1`; a separator divides one group from
  the next. A group with a `label` is a named `role="group"`. `label` names the toolbar, and
  `orientation` (`"horizontal"` or `"vertical"`) sets `aria-orientation` and
  the arrangement.

  The markup works on its own: every control is a native element reachable
  with Tab. Register the `ArmatureToolbar` hook from `armature-toolbar.js` in
  your LiveSocket to make the toolbar one tab stop. The hook gives the
  controls a roving tabindex: the arrow keys along the orientation move
  between enabled controls and wrap, Home and End go to the first and last,
  and natively disabled controls are skipped. It keeps the tabindex right
  after every LiveView patch. The toolbar holds no application state: the
  caller owns what each control does and whether it is pressed or disabled.
  """
  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))
  attr(:rest, :global)

  slot :group, required: true do
    attr(:label, :string)
  end

  def toolbar(assigns) do
    assigns =
      assign(assigns,
        separator_orientation:
          if(assigns.orientation == "vertical", do: "horizontal", else: "vertical")
      )

    ~H"""
    <div
      id={@id}
      class={["armature-toolbar"]}
      role="toolbar"
      aria-label={@label}
      aria-orientation={@orientation}
      phx-hook="ArmatureToolbar"
      {@rest}
    >
      <%= for {group, index} <- Enum.with_index(@group) do %>
        <div
          :if={index > 0}
          class={["armature-toolbar-separator"]}
          role="separator"
          aria-orientation={@separator_orientation}
        >
        </div>
        <div
          class={["armature-toolbar-group"]}
          role={group[:label] && "group"}
          aria-label={group[:label]}
        >
          {render_slot(group)}
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Named page controls and a polite atomic range announcement. The caller owns page state.

  Send `page` to `page_event`. Use page 1 of 1 and range 0–0 for no results.
  Supplying `page_sizes` and `size_event` adds a labelled select sending `page_size`.

  The words are the caller's: `label` names the navigation (default "Table
  pages"), `previous_label` and `next_label` are the buttons' visible text and
  accessible names (default "Previous" and "Next"), and `page_size_label`
  labels the size select (default "Records per page"). `range_label` is a
  function from `first`, `last` and `total` to the range text (default
  "26–50 of 2,000"), so a translation controls word order and grouping. The
  buttons have the ids `<id>-previous` and `<id>-next`.
  """
  attr(:id, :string, required: true)
  for {name, type, opts} <- @paging_attributes, do: attr(name, type, opts)

  def pagination(assigns) do
    assigns =
      assign(assigns, :range_label, assigns.range_label || (&default_range_label/3))

    ~H"""
    <nav id={@id} class={["armature-pagination"]} aria-label={@label}>
      <span id={@id <> "-range"} role="status" aria-live="polite" aria-atomic="true">{@range_label.(
        @first,
        @last,
        @total
      )}</span>
      <form
        :if={@page_sizes != [] && @size_event}
        id={@id <> "-size-form"}
        phx-change={@size_event}
        phx-submit={@size_event}
      >
        <Atoms.label for={@id <> "-size"}>{@page_size_label}</Atoms.label>
        <Atoms.select id={@id <> "-size"} name="page_size" value={@page_size} options={@page_sizes} />
      </form>
      <Atoms.button
        id={@id <> "-previous"}
        variant="secondary"
        phx-click={@page_event}
        phx-value-page={max(1, @page - 1)}
        disabled={@page <= 1}
      >{@previous_label}</Atoms.button>
      <Atoms.button
        id={@id <> "-next"}
        variant="secondary"
        phx-click={@page_event}
        phx-value-page={min(@pages, @page + 1)}
        disabled={@page >= @pages}
      >{@next_label}</Atoms.button>
    </nav>
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
        <Atoms.status :if={@status} label={@status} />
      </div>
      <div :if={@actions != []} class={["armature-record-actions"]}>{render_slot(@actions)}</div>
    </header>
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

  defp default_count_label(total), do: "#{format_count(total)} results"

  defp default_range_label(first, last, total),
    do: "#{format_count(first)}–#{format_count(last)} of #{format_count(total)}"

  defp format_count(count) do
    count |> Integer.to_string() |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
  end
end
