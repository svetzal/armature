defmodule Armature.Components.Layouts do
  @moduledoc """
  Baseline layouts. They arrange their children and carry no meaning or styling
  of their own, so moving content between arrangements never changes it.
  """
  use Phoenix.Component

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
    <div class={["armature-grid"]} {@rest}>
      <div class={["armature-grid-items"]}>{render_slot(@inner_block)}</div>
    </div>
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
end
