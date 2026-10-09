defmodule Example.Inventory.Second do
  @moduledoc false
  use Phoenix.Component
  alias Example.First, as: Primitive

  defmodule Nested do
    @moduledoc false
    use Phoenix.Component
    alias Example.Second, as: Primitive
    def markup(assigns), do: ~H"<Primitive.text />"
  end

  def capture do
    import Example.First, except: [text: 1]
    {&text/1, &mark/1}
  end

  def text(assigns), do: ~H"<span>Example</span>"
end
