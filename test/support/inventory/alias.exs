defmodule Example.Inventory.Alias do
  @moduledoc false
  alias Example.First
  def capture, do: &First.text/1
end
