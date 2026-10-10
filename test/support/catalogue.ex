defmodule Armature.CatalogueTest.EmptyExamples do
  @behaviour Armature.Catalogue.Examples
  @impl true
  def examples(_id), do: []
end

defmodule Example.Catalogue.Components do
  @moduledoc false
  use Phoenix.Component
  @doc "A synthetic extension with a visible name."
  attr(:label, :string, default: "Example extension")

  def marker(assigns) do
    ~H"""
    <span id="example-extension">{@label}</span>
    """
  end
end

defmodule Example.Catalogue.Registry do
  @behaviour Armature.Registry
  @impl true
  def modules, do: Armature.UI.Registry.modules() ++ [Example.Catalogue.Components]
  @impl true
  def nodes do
    Armature.UI.Registry.nodes() ++
      [
        %Armature.Registry.Node{
          id: :marker,
          level: :atom,
          module: Example.Catalogue.Components,
          function: :marker,
          purpose: "A synthetic extension."
        }
      ]
  end
end

defmodule Example.Catalogue.Examples do
  @behaviour Armature.Catalogue.Examples
  @impl true
  def examples(:marker),
    do: [
      %{
        title: "Extension",
        description: "Consumer-supplied example.",
        render: &Example.Catalogue.Components.marker/1
      }
    ]

  def examples(id), do: Armature.Catalogue.BaselineExamples.examples(id)
  @impl true
  def init, do: Armature.Catalogue.BaselineExamples.init()
  @impl true
  def handle_event(event, params, state),
    do: Armature.Catalogue.BaselineExamples.handle_event(event, params, state)
end

defmodule Armature.CatalogueTest.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  import Armature.Catalogue.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
  end

  scope "/" do
    pipe_through(:browser)

    armature_catalogue("/ui",
      registry: Armature.UI.Registry,
      examples: Armature.Catalogue.BaselineExamples
    )

    armature_catalogue("/overrides",
      registry: Armature.UI.Registry,
      examples: Armature.Catalogue.BaselineExamples,
      live_session_name: :override_catalogue,
      token_stylesheets: [Path.expand("../fixtures/catalogue-tokens.css", __DIR__)]
    )

    armature_catalogue("/empty",
      registry: Armature.UI.Registry,
      examples: Armature.CatalogueTest.EmptyExamples,
      live_session_name: :empty_catalogue
    )
  end

  scope "/nested", Armature.CatalogueTest do
    pipe_through(:browser)

    armature_catalogue("/ui",
      registry: Example.Catalogue.Registry,
      examples: Example.Catalogue.Examples,
      live_session_name: :extension_catalogue
    )
  end
end

defmodule Armature.CatalogueTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :armature
  @session_options [store: :cookie, key: "catalogue_test", signing_salt: "catalogue"]
  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])
  plug(Plug.Session, @session_options)
  plug(Armature.CatalogueTest.Router)
end
