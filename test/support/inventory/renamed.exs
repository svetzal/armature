defmodule Example.Inventory.Renamed do
  @moduledoc false
  alias Example.First, as: Primitive
  def capture, do: &Primitive.text/1
end
