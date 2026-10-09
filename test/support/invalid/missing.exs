defmodule Example.Invalid.Missing do
  @moduledoc false
  use Phoenix.Component
  import Example.First, except: [text: 1]
  def item(assigns), do: ~H"<.text /><.mark />"
end
