defmodule Armature.Catalogue.Router do
  @moduledoc """
  Mounts the development catalogue inside the consumer's browser scope.

  Import this module and call `armature_catalogue/2` inside a scope guarded by
  your application's `:dev_routes` compile-time flag. The routes inherit the
  scope's pipeline and root layout; load Armature's stylesheet in that layout.
  """

  @doc """
  Mounts a catalogue for the required `:registry` and `:examples` modules.

  `:live_session_name` defaults to `:armature_catalogue`. Supply distinct atom
  names when mounting more than one catalogue in a router.
  """
  defmacro armature_catalogue(path, options) do
    registry = Keyword.fetch!(options, :registry)
    examples = Keyword.fetch!(options, :examples)
    session = Keyword.get(options, :live_session_name, :armature_catalogue)

    quote do
      scope unquote(path), alias: false do
        import Phoenix.LiveView.Router

        live_session unquote(session),
          on_mount: [{Armature.Catalogue.CatalogueLive, {unquote(registry), unquote(examples)}}] do
          live("/", Armature.Catalogue.CatalogueLive, :index)
        end
      end
    end
  end
end
