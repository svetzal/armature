defmodule Example.Inventory.RemoteCall do
  @moduledoc false
  def call(assigns), do: Example.First.text(assigns)
end
