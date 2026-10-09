defmodule Example.First do
  @moduledoc false
  use Phoenix.Component
  def text(assigns), do: ~H"<span>Example</span>"
  def mark(assigns), do: ~H"<span>Example</span>"
end

defmodule Example.Second do
  @moduledoc false
  use Phoenix.Component
  def text(assigns), do: ~H"<span>Example</span>"
  defmacro ready, do: :ok
end

defmodule Example.Compositions do
  @moduledoc false
  use Phoenix.Component
  alias Example.First
  def aliased(assigns), do: ~H"<First.text />"
  # Deliberately change lexical scope after a definition to regress alias ordering.
  # credo:disable-for-next-line /Credo.Check.Readability.(StrictModuleLayout|SeparateAliasRequire)$/
  alias Example.Second, as: Primitive
  def renamed(assigns), do: ~H"<Primitive.text />"
  # This import must follow earlier definitions to test its lexical extent.
  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  import Example.Second, only: [text: 1]
  def imported(assigns), do: ~H"<.text />"

  def scoped(assigns) do
    alias Example.Second, as: First
    ~H"<First.text />"
  end

  def outside(assigns), do: ~H"<First.text />"
  def unknown(assigns), do: ~H"<.missing />"
  def missing(assigns), do: ~H"<span>Example</span>"
end

defmodule Example.Outer do
  @moduledoc false
  use Phoenix.Component
  alias Example.First, as: Primitive
  def before(assigns), do: ~H"<Primitive.text />"
  # Deliberately change lexical scope after a definition to regress alias ordering.
  # credo:disable-for-next-line /Credo.Check.Readability.(StrictModuleLayout|SeparateAliasRequire)$/
  alias Example.Second, as: Primitive
  # This import deliberately starts after the earlier component definition.
  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  import Example.First, only: [text: 1]
  def after_alias(assigns), do: ~H"<Primitive.text /><.text />"

  def local_import(assigns) do
    import Example.First, except: [text: 1]
    import Example.Second, only: [text: 1]
    ~H"<.text />"
  end

  def after_function(assigns), do: ~H"<.text />"

  def branches(assigns) do
    first =
      if assigns[:first] do
        alias Example.First, as: Primitive
        ~H"<Primitive.text />"
      end

    second = ~H"<Primitive.text />"
    {first, second}
  end

  defmodule Inner do
    @moduledoc false
    use Phoenix.Component
    def inherited(assigns), do: ~H"<Primitive.text />"
    # Override the inherited alias only after checking the inherited scope.
    # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
    alias Example.First, as: Primitive
    def changed(assigns), do: ~H"<Primitive.text />"
    def text(assigns), do: ~H"<span>Example</span>"
    def self_alias(assigns), do: ~H"<Inner.text />"
    def self_module(assigns), do: (&__MODULE__.text/1).(assigns)
  end

  def after_nested(assigns), do: ~H"<Primitive.text />"
end

defmodule Inner do
  @moduledoc false
  use Phoenix.Component
  def text(assigns), do: ~H"<span>Example</span>"
end

defmodule Example.Required do
  @moduledoc false
  use Phoenix.Component
  require Example.Second, as: Primitive
  Primitive.ready()
  def item(assigns), do: ~H"<Primitive.text />"
  def item(left, right), do: {left, right}
end

defmodule Example.RepeatedImports do
  @moduledoc false
  use Phoenix.Component
  import Example.First, only: [text: 1]
  import Example.First, except: []
  def imported(assigns), do: ~H"<.text /><.mark />"
  def mark(assigns), do: ~H"<span>Example</span>"
  def item(assigns), do: ~H"<First.text /><Elixir.Example.First.text />"
end

defmodule First do
  @moduledoc false
  use Phoenix.Component
  def text(assigns), do: ~H"<span>Example</span>"
end

defmodule Example.PrivateHelpers do
  @moduledoc false
  use Phoenix.Component
  import Example.First, only: [mark: 1]
  alias Example.First, as: Primitive
  alias Example.{Second, Required}

  def item(%{kind: :one} = assigns), do: ~H"<.helper /><Primitive.text />"
  def item(assigns), do: ~H"<.mark /><Second.text /><Required.item />"
  defp helper(assigns), do: ~H"<.helper /><.local />"
  def local(assigns), do: ~H'<.link href="/">Example</.link><.custom_builtin />'
  def custom_builtin(assigns), do: ~H"<span>Example</span>"
  def ordinary(a, b), do: {a, b}
end

defmodule Example.Guarded do
  @moduledoc false
  use Phoenix.Component
  import Example.First, except: [text: 1]
  def item(assigns) when is_map(assigns), do: ~H"<.text /><.mark />"
  def text(assigns), do: ~H"<span>Example</span>"
end

defmodule Example.External do
  @moduledoc false
  use Phoenix.Component
  def link(assigns), do: ~H"<span>Example</span>"
end

defmodule Example.BuiltinNames do
  @moduledoc false
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  import Example.External, only: [link: 1]
  alias Phoenix.Component, as: Framework
  def item(assigns), do: ~H"<.link /><Framework.form for={%{}}>Example</Framework.form>"
end

defmodule Example.WithoutDebugInfo do
  @moduledoc false
  @compile {:debug_info, false}
  use Phoenix.Component
  def text(assigns), do: ~H"<span>Example</span>"
end

defmodule Primitive do
  @moduledoc false
  use Phoenix.Component
  def text(assigns), do: ~H"<span>Example</span>"
end
