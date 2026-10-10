defmodule Armature.Components do
  @moduledoc """
  Accessible baseline atoms, layouts and form molecules.

  Import this module in consumer HTML helpers. Styling comes from
  `priv/static/armature.css` and the consumer's token values. Give standalone
  controls a visible label or an accessible name; `field/1` supplies a label
  and validation relationships for form controls.
  """
  use Phoenix.Component

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
      <label for={@id} class={["armature-label"]}>{@label}</label>
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
          <%!-- An unchecked box submits nothing; the hidden input sends "false" instead. --%>
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
end
