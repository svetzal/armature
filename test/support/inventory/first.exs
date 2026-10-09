defmodule Example.Inventory.First do
  @moduledoc false
  use Phoenix.Component
  import Example.First, only: [text: 1]
  alias Example.First
  alias Example.First, as: Primitive
  def aliased, do: &First.text/1
  def renamed, do: &Primitive.text/1
  def imported, do: &text/1
  def called(assigns), do: text(assigns)
  def remote(assigns), do: Example.First.text(assigns)
  def markup(assigns), do: ~H"<Primitive.text />"
end
