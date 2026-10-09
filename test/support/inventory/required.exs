defmodule Example.Inventory.Required do
  @moduledoc false
  require Example.Second, as: Primitive
  Primitive.ready()
  def capture, do: &Primitive.text/1
end
