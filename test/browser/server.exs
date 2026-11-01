# Test-only HTTP host: real components, catalogue, LiveView and packaged assets.
Logger.configure(level: :warning)

defmodule Armature.Browser.Layout do
  use Phoenix.Component

  def root(assigns) do
    assigns = assign(assigns, :theme, assigns.conn.params["theme"])

    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-armature-theme={@theme}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>Armature browser fixtures</title>
        <link rel="icon" href="data:," />
        <link rel="stylesheet" href="/assets/armature.css" />
        <link rel="stylesheet" href="/browser/fixtures.css" />
        <script src="/assets/armature-theme.js">
        </script>
        <script type="module" src="/browser/connect.js">
        </script>
      </head>
      <body>{@inner_content}</body>
    </html>
    """
  end
end

defmodule Armature.Browser.Fixtures do
  use Phoenix.Component
  alias Armature.Components.Atoms
  alias Armature.Components.Layouts
  alias Armature.Components.Molecules
  alias Armature.Components.Organisms
  alias Armature.Components.Templates

  def page(assigns) do
    assigns =
      assign(assigns,
        groups: [
          %{label: "Examples", items: [%{label: "Second", href: "/fixtures?destination=second"}]}
        ],
        rows: Enum.map(1..20, &%{id: "r#{&1}", name: "Record #{&1}", count: &1})
      )

    ~H"""
    <Molecules.theme_switch id="theme-one">
      <Atoms.button type="submit">Apply theme</Atoms.button>
    </Molecules.theme_switch>
    <Molecules.theme_switch id="theme-two" label="Appearance" />
    <div id="shell-host">
      <Templates.app_shell
        id="shell"
        heading="Examples"
        heading_id="heading"
        context="Library"
        title="Library"
        subtitle="Example application"
        home_patch="/fixtures"
        items={[%{label: "Overview", href: "/fixtures", current: true}]}
      >
        <:mark>
          <svg viewBox="0 0 2 5" fill="currentColor"><path d="M1 0 2 2.5 1 5 0 2.5Z" /></svg>
        </:mark>
        <p>Component fixtures</p>
      </Templates.app_shell>
    </div>
    <div id="nav-host">
      <Organisms.grouped_nav id="navigation" label="Examples" event="choose" groups={@groups} />
    </div>
    <Atoms.button id="open-example" type="submit" form="navigation-form">Open example</Atoms.button>
    <div id="grid-host">
      <Layouts.grid id="panels">
        <Organisms.panel id="first-panel" heading="First">First panel</Organisms.panel>
        <Organisms.panel id="second-panel" heading="Second">Second panel</Organisms.panel>
      </Layouts.grid>
    </div>
    <section aria-label="Controls">
      <Atoms.button id="enabled">Save</Atoms.button>
      <Atoms.button id="disabled" disabled>Unavailable</Atoms.button>
      <label for="valid">Name</label><Atoms.input id="valid" />
      <label for="invalid">Required name</label>
      <Atoms.input id="invalid" aria-invalid="true" aria-describedby="invalid-message" />
      <p id="invalid-message">Enter a name</p>
      <label for="disabled-input">Unavailable name</label><Atoms.input id="disabled-input" disabled />
      <Molecules.field id="check" type="checkbox" label="Include record" />
      <label for="list">Options</label><Atoms.select
        id="list"
        multiple
        options={[{"First", "first"}]}
      />
      <label for="single">Choice</label>
      <Atoms.select id="single" options={[{"First", "first"}, {"Second", "second"}]} />
      <div role="tablist" aria-label="Record views">
        <Atoms.button id="selected" role="tab" aria-selected="true" aria-controls="selected-panel">Selected record</Atoms.button>
      </div>
      <div id="selected-panel" role="tabpanel" aria-labelledby="selected">Record view</div>
    </section>
    <Organisms.data_table
      id="records"
      rows={@rows}
      caption="Records"
      select_event="select"
      selected_id="r1"
      inspector_id="details"
      sort_event="sort"
      sort_by="name"
      sort_direction="asc"
    >
      <:col :let={row} sort_key="name" label="Name" row_label>{row.name}</:col>
      <:col :let={row} label="Count" numeric>{row.count}</:col>
    </Organisms.data_table>
    <Organisms.inspector id="details" title="Record details">Choose a record</Organisms.inspector>
    <Organisms.side_nav
      id="plain-brand"
      title="Library"
      subtitle="Example application"
      label="Plain brand sections"
      items={[%{label: "Overview", href: "/fixtures"}]}
    />
    <Molecules.theme_switch id="theme-three" label="Colour scheme" label_visible />
    <Molecules.toolbar id="plain-toolbar" label="Plain actions">
      <:group>
        <Molecules.icon_button id="plain-add" icon="plus" label="Add" />
        <Molecules.icon_button id="plain-edit" icon="pencil" label="Edit" disabled />
      </:group>
      <:group><Molecules.icon_button id="plain-more" icon="ellipsis" label="More actions" /></:group>
    </Molecules.toolbar>
    """
  end
end

defmodule Armature.Browser.Controller do
  use Phoenix.Controller, formats: [:html], layouts: []

  def index(conn, _params) do
    content = Armature.Browser.Fixtures.page(%{__changed__: nil})

    html(
      conn,
      Phoenix.HTML.Safe.to_iodata(
        Armature.Browser.Layout.root(%{__changed__: nil, conn: conn, inner_content: content})
      )
    )
  end
end

defmodule Armature.Browser.Router do
  use Phoenix.Router
  import Armature.Catalogue.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_query_params)
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, html: {Armature.Browser.Layout, :root})
  end

  pipeline :strict do
    plug(:put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; script-src 'self'; style-src 'self'; font-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'self'"
    })
  end

  scope "/" do
    pipe_through([:browser, :strict])
    get("/fixtures", Armature.Browser.Controller, :index)
  end

  scope "/" do
    pipe_through(:browser)

    armature_catalogue("/ui",
      registry: Armature.UI.Registry,
      examples: Armature.Catalogue.BaselineExamples
    )
  end
end

defmodule Armature.Browser.ErrorHTML do
  def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule Armature.Browser.Endpoint do
  use Phoenix.Endpoint, otp_app: :armature
  @session_options [store: :cookie, key: "browser", signing_salt: "browser"]
  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])
  plug(Plug.Static, at: "/assets", from: {:armature, "priv/static"})
  plug(Plug.Static, at: "/browser", from: "test/browser", only: ~w(connect.js fixtures.css))
  plug(Plug.Static, at: "/phoenix", from: {:phoenix, "priv/static"})
  plug(Plug.Static, at: "/live-view", from: {:phoenix_live_view, "priv/static"})
  plug(Plug.Session, @session_options)
  plug(Armature.Browser.Router)
end

Application.put_env(:armature, Armature.Browser.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: 4022],
  url: [host: "127.0.0.1", port: 4022],
  secret_key_base: String.duplicate("b", 64),
  live_view: [signing_salt: "armature-browser"],
  pubsub_server: Armature.Browser.PubSub,
  render_errors: [formats: [html: Armature.Browser.ErrorHTML], layout: false],
  server: true
)

{:ok, supervisor} =
  Supervisor.start_link(
    [
      {Phoenix.PubSub, name: Armature.Browser.PubSub},
      Armature.Browser.Endpoint
    ],
    strategy: :one_for_one
  )

# Keep the script owner alive; Playwright terminates the entire server process group.
monitor = Process.monitor(supervisor)

receive do
  {:DOWN, ^monitor, :process, ^supervisor, reason} ->
    raise "browser server stopped: #{inspect(reason)}"
end
