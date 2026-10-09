defmodule Example.Inventory.Imported do
  @moduledoc false
  import Example.First, only: [text: 1]
  def capture, do: &text/1
end
