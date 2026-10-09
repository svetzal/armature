defmodule Example.Inventory.Markup do
  @moduledoc false
  use Phoenix.Component
  alias Example.First, as: Primitive
  def markup(assigns), do: ~H"<Primitive.text />"
end
