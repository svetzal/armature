defmodule Example.Inventory.Outer do
  @moduledoc false
  defmodule Inner do
    @moduledoc false
    use Phoenix.Component
    def capture, do: &Inner.text/1
    def text(assigns), do: ~H"<span>Example</span>"
    def markup(assigns), do: ~H"<Inner.text />"
    def self_capture, do: &__MODULE__.text/1
  end
end
