# Component catalogue

The catalogue is a development page for the registry your application declares.
It lists baseline components and your extensions together, grouped in level
order. Each node shows its purpose, live examples and its function's `@doc`
text as usage and accessibility notes. Uses and Used by links come directly
from `nodes/0`; do not maintain a second graph. Document accessibility behaviour
in each component's `@doc`.

## Mounting

Import the router macro, then mount it inside your existing browser scope:

```elixir
import Armature.Catalogue.Router

if Application.compile_env(:example, :dev_routes) do
  scope "/" do
    pipe_through :browser
    armature_catalogue "/dev/ui",
      registry: Example.UI.Registry,
      examples: Example.UI.Examples,
      token_stylesheets: ["assets/css/tokens.css"]
  end
end
```

Use your application's existing `:dev_routes` compile-time setting. Keep this
scope out of production; the catalogue does not add authentication. It defines
LiveView routes only and inherits your pipeline, root layout and LiveSocket.
Load `armature.css` and your token overrides in that layout, just as for your
other components. No additional hooks or JavaScript bundles are required.
Nested and aliased scopes are supported. The live session defaults to
`:armature_catalogue`; give multiple mounts distinct `:live_session_name` atom
options, following the mountable Phoenix page pattern.

A URL such as `/dev/ui?node=field` selects a component. Navigation uses patches,
so browser Back and Forward restore entries without resetting example state.
Unknown identifiers display the index safely. The component navigation marks
its current entry with `aria-current="page"`, and navigation moves focus to
the new page heading.

The theme control defaults to Auto, which sets no attribute: the catalogue
inherits your page's tokens, so components look exactly as they do in your
application. Light and Dark set `data-armature-theme` on the catalogue
container, which declares the full light or dark token set there. They show
your look only if your overrides also match `[data-armature-theme="light"]`
and `[data-armature-theme="dark"]`; see the README token stylesheet example.

## Tokens

Tokens is the first navigation entry, before Atoms, at `/dev/ui?section=tokens`.
It is generated from `Armature.Tokens.all/0`, grouped by first appearance of
its groups in the contract and retaining token order within each group.
Tokens are foundations, not registry nodes. The page shows colour roles and
swatches, every required contrast pair, the sans type scale and tabular
numerals, spacing, radii, control and row density, cue width and focus rings.
Samples render with `var(--armature-…)`, so the theme control and the token
stylesheets loaded in your layout govern their appearance.

The optional `:token_stylesheets` router option lists consumer CSS files in
load order, relative to the application's working directory (absolute paths
also work). Files are read at request time after Armature's shipped defaults;
there is no polling. Keep the catalogue in development routes. The option
reads files for server calculations; it does not load CSS into the browser.
Load those same files in your existing layout or asset bundle.

Every required colour pair reports its server-calculated WCAG ratio, minimum
and **Pass** or **Fail** in every context: Light and Dark in Auto, each
explicit theme under a matching system preference, and each explicit theme
under the opposite system preference.
Auto evaluates inherited `:root` tokens under each system preference.
Explicit modes evaluate the theme container's own declarations over those
inherited values. Thus a root-only override can change Auto while leaving an
explicit theme unchanged. Values for all six contexts are listed alongside
each token, independent of the currently selected visual theme.

See [the token guide](tokens.md#checking-consumer-overrides) for the supported
stylesheet syntax and the one-call consumer test.

## Supplying examples

Implement `Armature.Catalogue.Examples`. Each node id maps to a list of maps
with a title, a short state description and a function component capture:

```elixir
defmodule Example.UI.Examples do
  use Phoenix.Component
  @behaviour Armature.Catalogue.Examples

  @impl true
  def examples(:custom_action) do
    [%{title: "Available action", description: "Activation updates a local count.", render: &action/1}]
  end

  def examples(id), do: Armature.Catalogue.BaselineExamples.examples(id)

  @impl true
  def init do
    Armature.Catalogue.BaselineExamples.init() |> Map.put(:activations, 0)
  end

  @impl true
  def handle_event("custom:activate", _params, state) do
    %{state | activations: state.activations + 1}
  end

  def handle_event(event, params, state) do
    Armature.Catalogue.BaselineExamples.handle_event(event, params, state)
  end

  attr :state, :map, required: true
  defp action(assigns) do
    ~H"""
    <Armature.Components.button phx-click="custom:activate">Activate</Armature.Components.button>
    <p role="status">Activated {@state.activations} times.</p>
    """
  end
end
```

Render callbacks receive `@state`. The optional `init/0` callback initializes
it once per mount (including disconnected rendering); without it, state is an
empty map. The optional `handle_event/3` callback receives event name, params
and current state, and returns the next state. Keep callbacks free of
persistence and external effects. All demonstrations share that state, including
when navigating between related nodes. Refresh resets it. Use distinct event
names; `catalogue:` is reserved. Return unchanged state for unknown events.

Returning `[]` renders “No examples supplied for this component.” Demo
components can remain private and are not registered library components.
Examples with multiple entries must use unique DOM ids throughout.

For Armature alone, use `Armature.UI.Registry` and
`Armature.Catalogue.BaselineExamples`. The baseline demonstrates meaningful
control and feedback states, all layouts and 200 generated records with
complete-set search, sorting, 10/25/50-row pages and retained selection. Run
`OPEN=0 PORT=4021 elixir examples/preview.exs` to serve the same catalogue at `/`.
