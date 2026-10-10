# Armature usage rules

Armature is the component library and design-system governance for this
application. Build interface from its components, style through its tokens,
and register what you add. Full guides: `deps/armature/README.md` and
`deps/armature/guides/` (components, tokens, catalogue).

## Components

- Use `Armature.Components` for interface elements. Import it in the web
  module's HTML helpers with `import Phoenix.Component, except: [link: 1]`
  followed by `import Armature.Components`, or alias it.
- Prefer Armature components over Phoenix's generated core components and over
  hand-written markup: `button`, `link`, `field`, `status`, `notice`, `facts`,
  `panel`, `data_table`, `table_toolbar`, `pagination`, `inspector`,
  `record_header`, and the layouts `stack`, `cluster`, `grid` and `split`.
- Forms: use `field` with `field={@form[:name]}` and a visible `label`. Use
  `type` for `select`, `textarea` and `checkbox`. Do not hand-build label,
  hint and error markup; `field` binds them with `aria-describedby` and
  `aria-invalid`. Pass `translate_error` to use the application's Gettext.
- Application frame: build page frames from `app_shell`, `side_nav`, `top_bar`,
  `page_heading` and `grouped_nav`. Use `theme_switch` for light, dark and
  automatic themes.
- `icon` wraps your own inline SVG as decoration only. Put the accessible name
  on the control, never on the icon.
- Do not put Tailwind or other utility classes on Armature components or copy
  their markup. Extend instead (see below).

## Tables

- `data_table` takes `rows`, a `caption` and `:col` slots. Mark numeric columns
  `numeric`. Sorting sends `sort_event` with the column's `sort_key`; the
  application owns ordering, filtering and paging state.
- Selectable rows: set `select_event`, `selected_id` and `inspector_id`, and
  mark one column `row_label`. That column's content becomes the row's only
  button. A selectable row contains exactly one action. For rows that need more
  actions, use a non-selectable table with links, or a details pattern.
- Use `density="compact"` for data-heavy screens.

## Tokens and styling

- Armature styles everything through `--armature-*` CSS custom properties in
  cascade layers. Change the look by overriding token values in unlayered CSS
  imported after `armature.css`. Never edit Armature's stylesheet or copy it.
- Override a token under every selector you need: `:root`, the
  `@media (prefers-color-scheme: dark)` block, and
  `[data-armature-theme="light"]` and `[data-armature-theme="dark"]`.
  Omit `data-armature-theme` for automatic theming; there is no `"auto"` value.
- Write your own component styles with Armature tokens, not literal colours,
  sizes or fonts.
- Keep contrast enforced: add a test that calls
  `Armature.Tokens.Values.check!(["assets/css/your-tokens.css"])` for the files
  that override tokens. It fails when an override breaks a required pair.

## Extending

- Levels compose downward: tokens, atoms, layouts, molecules, organisms,
  templates. An organism may use another organism, never itself. Layouts
  arrange only and use atoms only.
- Build an application component from Armature components at lower levels,
  give it `attr` and `slot` declarations and `@doc`, and style it with tokens.
- Declare every component in a module that implements `Armature.Registry`
  (`nodes/0` and `modules/0`), listing Armature's baseline from
  `Armature.UI.Registry` plus your own nodes as `%Armature.Registry.Node{}`
  with `id`, `level`, `module`, `function`, `purpose` and `uses`.
- Check it in a test with `use Armature.RegistryCase, registry: MyApp.UI.Registry`.
  It verifies levels, uses against the compiled markup, and that every public
  component is declared. Component modules need debug info, which dev and test
  have by default.
- Add a component to Armature itself only when it is generic and a second real
  use needs it. Keep business compositions in the application.

## Catalogue

- Mount the catalogue in development only, inside the application's dev-routes
  guard: `import Armature.Catalogue.Router`, then
  `armature_catalogue "/dev/ui", registry: MyApp.UI.Registry, examples: MyApp.UI.Examples`.
- Supply examples by implementing `Armature.Catalogue.Examples` (`examples/1`,
  `init/0`, `handle_event/3`). Delegate unknown ids to
  `Armature.Catalogue.BaselineExamples`.
- Pass `token_stylesheets:` so the catalogue's contrast results use your
  overrides.

## Accessibility

- WCAG 2.2 AA is the floor. Use native elements; every control has a visible
  label or an accessible name; never show state by colour alone.
- Notices: use `result` for an outcome the person should hear; error results
  become alerts. Static guidance stays a plain notice.
- Check visual changes in a browser through the catalogue, in light and dark
  and at a narrow width, as well as with tests.
