defmodule Example.Invalid.Ambiguous do
  @moduledoc false
  use Phoenix.Component
  import Example.First, only: [text: 1]
  import Example.Second, only: [text: 1]
  def resolved(assigns), do: ~H"<Example.First.text />"
  def item(assigns), do: ~H"<.text />"
end
