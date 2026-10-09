defmodule Example.Inventory.ImportedCall do
  @moduledoc false
  import Example.First, only: [text: 1]
  def call(assigns), do: text(assigns)
end
