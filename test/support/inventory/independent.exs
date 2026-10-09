defmodule Example.Inventory.Independent do
  @moduledoc false
  def outside, do: &Primitive.text/1
end
