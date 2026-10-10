defmodule Armature.Catalogue.Examples do
  @moduledoc """
  Supplies demonstrations independently of a component registry.

  Each example has a `:title`, `:description` and `:render` function component
  capture. The component receives `@state`, shared across this catalogue's
  examples. Optional `init/0` and `handle_event/3` callbacks own that ephemeral
  state; refreshing the page resets it. Event names beginning `catalogue:` are
  reserved. Examples are demonstrations, not additions to the component library.
  """
  @type example :: %{
          title: String.t(),
          description: String.t(),
          render: (map() -> Phoenix.LiveView.Rendered.t())
        }
  @callback examples(atom()) :: [example()]
  @callback init() :: map()
  @callback handle_event(String.t(), map(), map()) :: map()
  @optional_callbacks init: 0, handle_event: 3
end
