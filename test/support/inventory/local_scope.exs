defmodule Example.Inventory.LocalScope do
  @moduledoc false
  def aliases do
    alias Example.Second, as: Primitive
    Primitive
  end

  def imports do
    import Example.First, except: [text: 1]
    &mark/1
  end

  def outside, do: &Primitive.text/1
  def local, do: &text/1
  def text(assigns), do: assigns
end
