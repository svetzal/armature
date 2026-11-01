defmodule Armature.Components.Atoms do
  @moduledoc """
  Baseline atoms: the smallest named controls and labels.

  Atoms compose nothing beneath them. Give standalone controls a visible label
  or an accessible name; `Armature.Components.Molecules.field/1` supplies a
  label and validation relationships for form controls.
  """
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]

  alias Armature.Components.Attributes

  @tones Attributes.tones()
  @input_attributes Attributes.input()
  @select_attributes Attributes.select()
  @textarea_attributes Attributes.textarea()

  @doc "An uppercase contextual label. It supplements a heading, rather than replacing it."
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def eyebrow(assigns) do
    ~H"""
    <p class={["armature-eyebrow"]} {@rest}>{render_slot(@inner_block)}</p>
    """
  end

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
  attr(:class, :any, default: nil)
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
      class={["armature-link", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </Phoenix.Component.link>
    """
  end

  @doc """
  A decorative glyph: a vendored icon by `name`, or the consumer's inline SVG in the slot.

  `name` is one of `Armature.Icons.names/0`. A literal unknown name warns at
  compile time and any unknown name raises `ArgumentError` when rendered.
  Supply either `name` or an inner SVG, not both. The icon is always hidden
  from assistive technology and drawn in `currentColor`; put the accessible
  name on the surrounding control.
  """
  attr(:name, :string, default: nil, values: [nil | Armature.Icons.names()])
  slot(:inner_block)

  def icon(%{name: nil, inner_block: []}) do
    raise ArgumentError, "icon needs a name or an inline SVG in its slot"
  end

  def icon(%{name: name, inner_block: [_ | _]}) when is_binary(name) do
    raise ArgumentError, "icon takes a name or an inline SVG, not both"
  end

  def icon(%{name: nil} = assigns) do
    ~H"""
    <span class={["armature-icon"]} aria-hidden="true">{render_slot(@inner_block)}</span>
    """
  end

  def icon(assigns) do
    assigns = assign(assigns, :glyph, Phoenix.HTML.raw(Armature.Icons.glyph!(assigns.name)))

    ~H"""
    <span class={["armature-icon"]} aria-hidden="true"><svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      focusable="false"
    >{@glyph}</svg></span>
    """
  end

  @doc "A native input. Supply a label association or aria-label when used alone."
  attr(:id, :string, required: true)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text")

  attr(:rest, :global, include: @input_attributes)

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
  attr(:rest, :global, include: @select_attributes)

  def select(assigns) do
    ~H"""
    <%!-- The wrapper draws the chevron; a select cannot hold generated content. --%>
    <span class={["armature-select-wrap"]}>
      <select id={@id} name={@name} multiple={@multiple} class={["armature-select"]} {@rest}>
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
    </span>
    """
  end

  @doc "A native multiline text control. Supply a label association or aria-label when used alone."
  attr(:id, :string, required: true)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)

  attr(:rest, :global, include: @textarea_attributes)

  def textarea(assigns) do
    ~H"""
    <textarea id={@id} name={@name} class={["armature-textarea"]} {@rest}>{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
    """
  end

  @doc "A compact status badge. Its label must express the meaning independently of its tone."
  attr(:label, :string, required: true)
  attr(:tone, :string, default: "neutral", values: @tones)
  attr(:rest, :global)

  def status(assigns) do
    ~H"""
    <span class={["armature-status", "armature-tone-#{@tone}"]} {@rest}>{@label}</span>
    """
  end
end
