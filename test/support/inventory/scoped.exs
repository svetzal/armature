defmodule Example.Inventory.Scoped do
  @moduledoc false
  def inside do
    alias Example.First, as: Primitive
    &Primitive.text/1
  end

  def outside, do: &Primitive.text/1
end
