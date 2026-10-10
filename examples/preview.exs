# Run with OPEN=0 PORT=4021 elixir examples/preview.exs for a headless preview.
Mix.install([
  {:phoenix_playground, "~> 0.1.9"},
  {:armature, path: Path.expand("..", __DIR__)}
])

defmodule PreviewLayout do
  use Phoenix.Component
  # Keep the one-file preview self-contained: the playground re-evaluates this
  # script on requests, so simultaneous font requests can race module compilation.
  @font_stylesheet Enum.reduce(
                     [400, 600],
                     File.read!(Path.expand("../priv/static/armature-fonts.css", __DIR__)),
                     fn weight, css ->
                       font =
                         File.read!(
                           Path.expand("../priv/static/fonts/barlow-#{weight}.woff2", __DIR__)
                         )

                       String.replace(
                         css,
                         "fonts/barlow-#{weight}.woff2",
                         "data:font/woff2;base64," <> Base.encode64(font)
                       )
                     end
                   )
  @stylesheet @font_stylesheet <> File.read!(Path.expand("../priv/static/armature.css", __DIR__))

  def root(assigns) do
    assigns = assign(assigns, :stylesheet, @stylesheet)

    content = ~H"""
    <style>
      <%= Phoenix.HTML.raw(@stylesheet) %>
    </style>
    {@inner_content}
    """

    PhoenixPlayground.Layout.render("root.html", assign(assigns, :inner_content, content))
  end
end

defmodule PreviewRouter do
  use Phoenix.Router
  import Armature.Catalogue.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, html: {PreviewLayout, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through(:browser)

    armature_catalogue("/",
      registry: Armature.UI.Registry,
      examples: Armature.Catalogue.BaselineExamples
    )
  end
end

PhoenixPlayground.start(
  plug: PreviewRouter,
  port: String.to_integer(System.get_env("PORT", "4020")),
  open_browser: System.get_env("OPEN", "1") == "1"
)
