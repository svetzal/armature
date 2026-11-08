# Baseline components

Add `use Armature.Components` to consumer HTML helpers, then exclude the
built-in link with `import Phoenix.Component, except: [link: 1]`. It imports the
five level modules: `Armature.Components.Atoms`, `Layouts`, `Molecules`,
`Organisms` and `Templates`. Load the Armature stylesheet and override its
tokens in your own CSS. Components share light and dark token values.

## Atoms

| Component | Uses | Purpose |
| --- | --- | --- |
| `eyebrow` | — | A contextual uppercase label. |
| `button` | — | A named native action. |
| `link` | — | A named navigation link. |
| `icon` | — | A decorative vendored glyph or consumer SVG. |
| `input` | — | A native single-line control. |
| `select` | — | A native option control. |
| `textarea` | — | A native multiline control. |
| `label` | — | A native label bound to its control. |
| `status` | — | A status expressed in words. |

## Layouts

| Component | Uses | Purpose |
| --- | --- | --- |
| `stack` | — | Vertical rhythm. |
| `cluster` | — | A wrapping inline group. |
| `grid` | — | Responsive minimum-width columns. |
| `split` | — | Two regions that stack. |

## Molecules

| Component | Uses | Purpose |
| --- | --- | --- |
| `theme_switch` | `icon`, `input` | A segmented system, light or dark choice of native radios. |
| `page_heading` | `eyebrow`, `cluster` | A page heading with context and actions. |
| `field` | `label`, `input`, `select`, `textarea` | A labelled control with hint and validation. |
| `facts` | — | Labelled record facts in a description list. |
| `notice` | — | Static guidance or reported results with actions. |
| `table_toolbar` | `label`, `input`, `icon`, `button` | A labelled search and announced result count. |
| `icon_button` | `button`, `icon` | A named square action or toggle showing only an icon. |
| `toolbar` | — | A named group of controls with one tab stop and arrow-key movement. |
| `pagination` | `label`, `button`, `select` | Named paging controls and an announced range. |
| `record_header` | `status` | A record heading with context and actions. |

## Organisms

| Component | Uses | Purpose |
| --- | --- | --- |
| `panel` | `cluster` | A named content panel with heading and actions. |
| `grouped_nav` | `eyebrow`, `link`, `label`, `select` | Grouped navigation with a labelled narrow-screen picker. |
| `top_bar` | `cluster` | A context band with actions. |
| `side_nav` | `eyebrow`, `link` | Named section navigation with a brand and footnote. |
| `data_table` | `button`, `icon` | A sortable native table with named record selection. |
| `inspector` | — | A named complementary details landmark. |

## Templates

| Component | Uses | Purpose |
| --- | --- | --- |
| `app_shell` | `link`, `side_nav`, `top_bar`, `page_heading` | An application shell with skip navigation and a page heading. |
| `table_inspector` | `link`, `split`, `table_toolbar`, `data_table`, `pagination`, `inspector` | A complete table and supporting details workflow. |

Tables are checked against `Armature.UI.Registry` by the test suite.

## Application shell

`app_shell` composes `side_nav`, `top_bar` and `page_heading`. Its first link
skips to the unique, focusable `heading_id`; the main landmark is named by that
heading. The skip link is a plain `href` fragment and the h1 has
`tabindex="-1"`, so it moves focus without JavaScript; its LiveView
`JS.focus` command is an enhancement. The skip link reads `skip_label`
(default "Skip to main content"). Set `title` and `subtitle` for your application's brand, `nav_label`
to name the rail's navigation (default "Main") and `section_label` for an
optional caption above its links. The brand and caption render only when you
give them. Navigation items have
`:label`, one of `:href`, `:patch` or `:navigate`, and optional `:id` and `:current`.
Set `home_patch` to make the wordmark a patch link back to your index.
Its accessible name is `home_label` (default: the title followed by " home").
The optional `mark` slot puts a logo or symbol (an `<img>` or inline SVG)
before the title, on the same row and inside its link. It renders only with a
title and is hidden from assistive technology, because the title names the
brand. Its height is `--armature-brand-mark-size`; its width follows the
image's aspect ratio.
Current links announce `aria-current="page"` and use weight as well as colour.
The caller owns URLs, selection and events. `heading_rest` forwards focus
commands to the h1. Optional `footnote`, `top_actions` and `heading_actions`
slots supply supporting content and named controls.

```heex
<.app_shell id="library" title="Library" context="Library / Overview"
  heading="Overview" heading_id="overview" eyebrow="Library / Overview"
  items={[%{label: "Overview", patch: "/overview", current: true}]}>
  <:top_actions><.theme_switch id="theme" value={@theme} event="theme" /></:top_actions>
  <:footnote>Example content</:footnote>
  <.grid>
    <.panel id="summary" heading="Summary"><p>Content</p></.panel>
    <.panel id="details" heading="Details"><p>Supporting content</p></.panel>
  </.grid>
</.app_shell>
```

`side_nav` names its navigation with `label` (default "Main"); give each
further navigation on a page its own name. Its `title`, `subtitle`,
`section_label` and `mark` are optional and render nothing when omitted.
`top_bar` carries a visible `context` and optional `actions`. `page_heading`
uses an h1 and optional `eyebrow` and `actions`; `eyebrow` alone adds context,
not a heading. `panel` names a region with its h2 and optional `actions`.
Express empty, loading, error and invalid content through notices or status
text in the content slot. Arrange panels with `grid`; they stack as space runs out.

`grouped_nav` takes `groups` of `%{label: text, items: items}` using the same
item contract. Its `label` names both the wide navigation and the narrow native
select. The select's empty option reads `prompt` (default "Choose a
destination") and its description reads `hint` (default "Choosing an option
opens its page."). Pass your own words, or translations, there. The select emits `destination` on `event`. Validate it against the
supplied destinations before calling `push_patch` or `push_navigate`. Its optional
content slot can supply guidance. Keep current selection in caller state.

`theme_switch` is a three-way pill toggle: a `fieldset` whose `legend`
carries `label` (default "Theme"), and three native radios named `theme` with
the values `"auto"`, `"light"` and `"dark"`. Their choices show a monitor, a
sun and a moon, and their names in words are the attributes `auto_label`,
`light_label` and `dark_label` (default "System", "Light" and "Dark").
`armature-theme.js` announces whichever name is rendered.
"System" is the name of `"auto"`: that choice follows the operating system or
browser preference, and the icon shows a screen. The choices sit in a rounded
track on the `--armature-recessed` surface, with no borders between them. The
checked choice is a raised thumb: a `--armature-paper` surface inside a
`--armature-control-border` boundary, with a `--armature-shadow` and an ink
icon. The other icons are muted and turn to ink on hover. State never rests
on colour alone. On a fine pointer the track is one
`--armature-control-height-compact` tall, so it fits a top bar; each choice is
at least `--armature-target-size` tall and a little wider, and grows to 44px
under a coarse pointer or a narrow viewport. In forced colours the track keeps
a border, the choice is a solid ring inside, and a focused choice is a double
ring outside. The legend is visually hidden by default; set `label_visible`
to show it beside the choices. Native radios give one tab stop and arrow-key movement.
Each radio has the id `<id>-auto`, `<id>-light` or `<id>-dark`.
In a LiveView it emits `theme` on `event`; the caller applies it.
On a page without LiveView, omit `event` and load `armature-theme.js` (see
the README), which applies, remembers and announces the choice, for example
"Theme: Dark". The form carries `data-armature-theme-switch` for the script;
the script skips any switch inside a LiveView. `"auto"` removes the theme
attribute, inheriting consumer tokens. In a handler, check the value against
`Armature.Components.themes/0` and set `data-armature-theme` to
`Armature.Components.theme_attribute/1`, which is `nil` for `"auto"` so the
attribute is omitted. Its optional content slot can explain
the choice or hold a submit button.

The rail is 210px wide, 155px below 800px, and becomes wrapping links below
520px, hiding its subtitle, label and footnote. These thresholds measure the
shell's own inline size. Grouped links become a labelled select when their own
container is below 180px. Panel grids measure their own container too. All visual
measurements and colours are tokens; container queries describe structural transitions. Navigation targets are at
least 44px high, including on wide screens. Rail focus and pale-pill inset
focus have separate contrast contracts. Forced colours retain native controls
and visible current-page outlines; reduced motion uses the base-layer policy.

## Controls and validation

`button` defaults to `type="button"`; use `type="submit"` explicitly in forms.
`link` forwards Phoenix's `navigate`, `patch` and `href` behavior. Native controls
preserve browser keyboard behavior. Standalone input, select and textarea atoms
need a caller-owned `label` atom or `aria-label`; `label` binds by `for`, and
`visually_hidden` keeps its name for assistive technology only. Use `field` for a
visible label, optional hint and errors bound to the control by stable ids.

```heex
<.field field={@form[:name]} label="Name" hint="Use a short name."
  translate_error={&translate_error/1} />
<.field id="category" name="category" type="select" label="Category"
  options={[{"First", "first"}, {"Second", "second"}]} value="first" />
<.field id="notes" name="notes" type="textarea" label="Notes" />
```

The consumer's `translate_error/1` receives `{message, options}` and returns a
translated string, including interpolation when needed. The default returns the
message unchanged. FormField errors are hidden until `Phoenix.Component.used_input?/1`
returns true; plain `errors` are strings and display immediately. Omit errors when
valid. Caller `aria-describedby` ids are preserved and must point at caller-owned
elements. `aria-invalid` is emitted only when displayed errors exist.
With plain name/value inputs, supply a stable unique `id`.

## Icons, icon buttons and toolbars

`icon` draws a glyph from Armature's base set by `name`, such as
`<.icon name="search" />`, or wraps your own inline SVG in its slot. Give it
one or the other: neither, or both, raises `ArgumentError`. An unknown name
raises when it renders, and a literal unknown name also warns at compile
time, so `mix compile --warnings-as-errors` catches a typo. The icon is
always hidden from assistive technology and drawn in `currentColor`, 16px
square (`--armature-text-large`). Keep the accessible name on the surrounding
control. Supply only decorative, noninteractive SVG in the slot.

The base set is 33 general-purpose glyphs vendored unchanged from
[Lucide](https://lucide.dev) (`lucide-static` 1.58.0, ISC licence; the licence
ships in `priv/icons/LICENSE.txt`). They keep Lucide's names:
`arrow-down`, `arrow-up`, `arrow-up-down`, `check`, `chevron-down`,
`chevron-left`, `chevron-right`, `chevron-up`, `circle-alert`, `circle-check`,
`copy`, `download`, `ellipsis`, `ellipsis-vertical`, `external-link`, `eye`,
`eye-off`, `funnel`, `info`, `menu`, `minus`, `monitor`, `moon`, `pencil`,
`plus`, `refresh-cw`, `search`, `settings`, `sun`, `trash-2`,
`triangle-alert`, `upload` and `x`. `Armature.Icons.names/0` returns them, so
a consumer can enumerate the set; the catalogue's `icon` page shows each one.
For any other glyph, pass your own SVG.

`icon_button` is a **molecule**: the `button` atom holding the `icon` atom
and nothing else. It is not a variant of `button`, because an atom composes
nothing and because its contract differs: an icon button has no visible
words, so its `label` is required. The label is visually hidden text inside
the button, which names it for assistive technology, voice control and page
translation, and it is also the native `title`. Use `icon` for a vendored
glyph or the slot for your own SVG. `variant` is `"secondary"` (the default,
because icon buttons usually sit in groups) or `"primary"`; `disabled`
renders the native attribute and the dashed disabled look of `button`. Set
`pressed` to `true` or `false` to make a toggle: it renders `aria-pressed`,
and a pressed button shows the `--armature-selected` surface inside a
`--armature-selected-cue` border with a `--armature-cue-width` marker bar
along its lower edge. The bar keeps the state visible without colour; a
disabled toggle keeps the bar in the muted colour, and forced colours draw a
pressed button as a solid ring inside and a focused one as a double ring
outside. Leave `pressed` unset for an ordinary action. The button is square:
`--armature-control-height-compact` on a fine pointer and at least 44px under
a coarse pointer or a narrow viewport, as `--armature-target-size` grows.
The caller owns the pressed state and sends it back on each render.

```heex
<.icon_button icon="plus" label="Add record" phx-click="add" />
<.icon_button icon="eye" label="Show hidden records" pressed={@show_hidden}
  phx-click="toggle_hidden" />
```

There is no tooltip beyond the native `title`. A custom tooltip that met
WCAG 1.4.13 (dismissible with Escape, hoverable, persistent) needs script and
focus management that this release leaves out; where sighted people need the
words, use a `button` with visible text and an icon instead.

`toolbar` is a **molecule** that arranges controls, such as `icon_button` and
`button`, under the ARIA toolbar pattern. It renders `role="toolbar"` named
by its required `label`, with `aria-orientation` from `orientation`
(`"horizontal"`, the default, or `"vertical"`). Each `group` slot holds
related controls; a `role="separator"` divider, oriented across the toolbar,
sits between one group and the next. A group with a `label` becomes a named
`role="group"`. The toolbar has no surface of its own and wraps when space
runs out, so it fits a top bar, panel or record header. It holds no
application state: the caller owns each control's event, pressed state and
disabled state.

```heex
<.toolbar id="record-actions" label="Record actions">
  <:group>
    <.icon_button icon="plus" label="Add" phx-click="add" />
    <.icon_button icon="pencil" label="Edit" phx-click="edit" />
    <.icon_button icon="trash-2" label="Delete" disabled={@selected == nil} phx-click="delete" />
  </:group>
  <:group label="View">
    <.icon_button icon="eye" label="Show hidden" pressed={@show_hidden} phx-click="toggle_hidden" />
  </:group>
  <:group><.icon_button icon="ellipsis" label="More actions" phx-click="more" /></:group>
</.toolbar>
```

### The toolbar hook

The server-rendered toolbar works on its own: every control is a native
element and each one is a Tab stop. The `ArmatureToolbar` hook makes the
toolbar one tab stop, as the pattern expects. When it mounts, it gives the
controls a roving tabindex. The arrow keys along the orientation (Left and
Right, or Up and Down for a vertical toolbar) move focus between controls and
wrap at the ends; Home and End move to the first and last control. Natively
disabled controls cannot take focus and are skipped; a control marked only
`aria-disabled="true"` stays reachable, as the pattern allows. Keys typed into
a text field, select or radio keep their native meaning. After every LiveView
patch the hook applies the tabindex again, keeping the control that last had
focus as the tab stop while it is present and enabled, else the first.

The hook is plain JavaScript with no dependencies in
`priv/static/armature-toolbar.js`, an ES module whose default export is the
hook. Import it in your `assets/js/app.js` and register it under the name the
markup uses, `ArmatureToolbar`:

```javascript
import ArmatureToolbar from "../../deps/armature/priv/static/armature-toolbar.js"

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ArmatureToolbar },
  params: { _csrf_token: csrfToken },
})
```

The path is relative to `assets/js/`. Phoenix's esbuild configuration puts
`deps` on `NODE_PATH`, so `"armature/priv/static/armature-toolbar.js"` also
works. A vendored copy (`{:armature, path: "vendor/armature"}`) imports from
`"../../vendor/armature/priv/static/armature-toolbar.js"`. If you already
spread other hooks, add it beside them:
`hooks: { ...colocatedHooks, ArmatureToolbar }`. Without the hook, LiveView
logs that the hook is unknown and the toolbar keeps working with Tab. On a
controller page the `phx-hook` attribute is inert, so the toolbar is a row of
ordinary Tab stops. The hook has no inline script or `eval` and sets no
inline styles, so it runs under `script-src 'self'`.

## Feedback

`status` labels must express meaning in words, such as "Complete" or "Needs review".
Tones are `neutral`, `success`, `warning` and `error`.

`notice` defaults to static guidance with no live region. Set `result` when reporting
an outcome: non-error results use `role="status"`, errors use `role="alert"`.
Optional `title` and `actions` support explanation and recovery.

```heex
<.notice id="saved-result" tone="success" result title="Saved">
  Your changes are saved.
  <:actions><.button variant="secondary">Continue</.button></:actions>
</.notice>
```

## Arrangement

`stack`, `cluster` and `grid` accept an inner slot; `split` also requires a
`secondary` slot. They add only arrangement, without landmarks, colour or borders.
Grid and split minimum item width comes from `--armature-layout-min-width`;
items stack when there is insufficient width. Gaps use `--armature-space-4`.

```heex
<.split id="regions">
  <p>First region</p>
  <:secondary><p>Second region</p></:secondary>
</.split>
```

Controls use target-size and control-height tokens, which default to at least
44px on coarse pointers and narrow screens. Consumers own accessible names,
unique ids, token contrast and complete workflow accessibility.

## Data browsing

`data_table` uses a native table with a required caption (visible by default;
`caption_hidden` makes it screen-reader-only), scoped column headings and a
keyboard-reachable named scroll region. An empty list renders `empty_label`
in words instead of an empty table. Each `col` slot receives a row; `numeric`
right-aligns values with tabular numbers. A `sort_key` with `sort_event` renders
a native button sending `%{"key" => key}`. Only the active sortable heading
has `aria-sort`; the caller sorts the rows and supplies `sort_by` and
`sort_direction` (`"asc"` or `"desc"`). The sort button's name is
`sort_label`, a function from the column label (default "Sort by Name"), so a
translation controls the word order. Sticky headings return to normal flow
while the scroll region contains focus, so they cannot cover a keyboard target.

Supply `select_event` and the id of an existing inspector to enable selection.
Mark exactly one `col` slot `row_label`. Its visible content becomes a native
button whose accessible name is the row label, with `aria-pressed` and
`aria-controls` pointing to the inspector. It sends `%{"id" => row_id}`;
the entire row also responds to pointer clicks. Focus within outlines the row;
selection retains its surface and inset accent bar without moving focus.
The default `row_id` reads `row.id`; override it with a function returning a
unique, DOM-safe identifier. Match `selected_id` to that function's return type.
A selectable table whose rows have no `:id` and no `row_id` raises a clear
error. A table without selection needs no identifier at all: rows without
one take their DOM ids from their position, such as `records-row-0`.

A selectable row contains **exactly one interactive element**, its row-label
button. All column content must be non-interactive, including the row label.
Declare action columns `interactive`; supplying one to a selectable table
raises a clear error. Rows needing further actions must use a non-selectable
table with explicit links or a details pattern instead. Row-label buttons
inherit cell typography with emphasis weight, no border or fill, and a minimum
24px target (44px on coarse pointers).

`table_toolbar` renders a labelled search form sending `%{"query" => query}`
to `search_event` on change or submit, an atomic polite result count from `total`,
and an optional `actions` slot. Searching is always the caller's responsibility.
Its words are attributes: `search_label` (default "Search records"),
`clear_label` for the clear button (default "Clear search") and `count_label`,
a function from `total` to the count text (default "1,234 results"), so a
translation controls the word order. `table_inspector` passes all three to its toolbar.
`pagination` receives `page`, `pages`, `first`, `last`, `total` and `page_event`;
its named buttons send `%{"page" => page}` and disable at the boundaries. For
an empty result set pass page 1 of 1 and range 0–0. Supplying `page_sizes` and
`size_event` adds a labelled select sending `%{"page_size" => size}`. Its range
is an atomic polite status, with grouping separators, such as "26–50 of 2,000".
`label` names the navigation (default "Table pages"), `previous_label` and
`next_label` are the buttons' visible text and accessible names (default
"Previous" and "Next"), and `page_size_label` labels the size select (default
"Records per page"). `range_label` is a function from `first`, `last` and
`total` to the range text (default "26–50 of 2,000"), so a translation
controls the word order and grouping. The buttons have the ids `<id>-previous`
and `<id>-next`. Phoenix delivers these event values as strings.

`inspector` is an `aside` named by its heading, with a stable `id` and
`tabindex="-1"` for skip-link access. It is never a live region. `record_header`
provides an h2, optional `context`, optional status in words and `actions`.

`table_inspector` is a **template**: it composes the complete data browsing
workflow rather than one semantic unit. It uses `split` to place the inspector
beside the table when there is room, then below it as the regions wrap. It
forwards the `col` slots, renders `actions` in the toolbar and `details` inside
the inspector. IDs derive from the template id, keeping the row-label buttons'
`aria-controls` and skip link connected to the actual landmark. Update
`selection_label` when selection changes; only this short status is announced,
without moving focus or announcing all details. Keep selection outside the
filtered and paged collection so it survives those operations. The skip link
reads `skip_label` (default "Skip to " followed by `inspector_title`), and
`sort_label` passes to the table.

```heex
<.table_inspector id="records" rows={@rows} caption="Example records"
  query={@query} search_event="search" total={@total}
  sort_by={@sort_by} sort_direction={@sort_direction} sort_event="sort"
  selected_id={@selected_id} select_event="select"
  selection_label={@selection_label} inspector_title="Record details"
  page={@page} pages={@pages} first={@first} last={@last} page_event="page"
  page_sizes={[10, 25, 50]} page_size={@page_size} size_event="size">
  <:col :let={row} label="Name" sort_key="name" row_label>{row.name}</:col>
  <:col :let={row} label="Score" numeric sort_key="score">{row.score}</:col>
  <:details>
    <%= if @selected do %>
      <.record_header id="selected-record" title={@selected.name} context={@selected.id} />
    <% else %>
      <p>Select a record to see its details.</p>
    <% end %>
  </:details>
</.table_inspector>
```

The mountable catalogue (also served by `examples/preview.exs`) demonstrates this contract with 200 generated records,
search across the complete set, text and numeric sorting, 10/25/50 page sizes,
and selection retained across search and paging. Its theme controls exercise
the same table, hover, selected and focus tokens in light and dark modes.

## Density and facts

`data_table` and `table_inspector` accept `density="default"` (the default) or
`density="compact"`. Default cells use 12px × 16px insets and 44px rows;
compact cells use 6px × 16px insets and 34px rows. Row heights are minimums:
wrapping content may grow them. Narrow screens and coarse pointers retain
44px control targets in either density. Secondary cell text can use a `small`
element; it occupies its own line at 11px.

```heex
<.facts>
  <:fact label="Identifier">R-001</:fact>
  <:fact label="Score">42</:fact>
</.facts>
```

Facts render as a native description list with muted labels and tabular,
emphasised values. They hold no record state. The toolbar's decorative search
icon and named Clear search button are built in; clearing sends an empty
`query` to the same `search_event`. The clear button appears for a nonempty query.

## Reference measurements

All names below have the `--armature-` prefix. Rem values use the browser's
16px default; they scale with the reader's font preferences. Row heights and
control sizes are minimums, allowing text to grow.

| Measurement | Token or component rule |
| --- | --- |
| Barlow 400/600, system fallback, swap loading | `font-sans`, `weight-normal`, `weight-emphasis`; optional `armature-fonts.css` |
| Body 14px, line height 1.5 | `text-base`, `line-height` |
| Cells, buttons, notices, search 13px | `text-control` |
| Hints, context, counts, ranges and fact labels 12px | `text-small` |
| Table headings, cell metadata and status chips 11px | `text-micro` |
| Record title 20px/600; inspector heading 14px/600 | `text-heading`, `text-base`, `weight-emphasis` |
| Numbers and counts tabular | Numeric cells, facts values, toolbar counts and pagination use `font-variant-numeric: tabular-nums` |
| Buttons: 32px minimum, 6px × 12px, 5px radius, 1px border | `control-height-compact`, `space-control`, `space-3`, `radius-base`, `border-width` |
| Buttons: accent/paper primary; paper secondary; subtle hover; 6px icon gap | Button variant rules, `hover-mix`, `space-control` |
| Icon buttons: square, 32px; coarse/narrow at least 44px; pressed surface, cue border and 3px lower bar | `control-height-compact`, `target-size`, `selected`, `selected-cue`, `cue-width` |
| Icons: 16px square in the current colour | `text-large`; `currentColor` stroke |
| Toolbar: 8px between groups, 4px within a group, 1px decorative separators | `space-2`, `space-1`, `border-width`, `line` |
| Inputs/selects: 36px minimum, 7px × 10px, 5px radius, control border | `control-height`, `space-input`, `space-detail`, `radius-base`, `control-border` |
| Toolbar fields: 32px minimum | `control-height-compact`; compact vertical inset in the search rule |
| Select chevron; native in forced colours | `chevron-size`, `chevron-angle`, `chevron-stop`; forced-colour appearance override |
| Status: 11px/600, 2px × 7px, 4px radius, 1px line border, tone background, no wrap | `text-micro`, `weight-emphasis`, `space-half`, `space-input`, `radius-small`, `border-width`, tone rules |
| Notice: unfilled, 3px rule, 11px × 14px, 13px, title 600 | `cue-width`, `space-notice`, `space-text`, `text-control`, `weight-emphasis`; accent/warning/error rule colours |
| Table headings: 11px/600, muted/canvas, 10px × 16px, sticky | `text-micro`, `weight-emphasis`, `muted`, `canvas`, `space-detail`, `space-4`; heading rule |
| Default cells: 13px, 12px × 16px, 44px rows | `text-control`, `table-cell-padding`, `table-row-height` |
| Compact cells: 6px × 16px, 34px rows | `table-cell-padding-compact`, `table-row-height-compact`; `data-density="compact"` |
| Rows: 1px line dividers, hover/focus surface, selected surface and 3px inset accent bar | `border-width`, `line`, `hover`, `selected`, `cue-width`, `accent`; first-cell shadow |
| Secondary cell line: muted, 11px | `td small`, `muted`, `text-micro` |
| Inline sorting with faint arrow, stronger on hover/active | `.armature-table thead .armature-button`, `sort-opacity`, `opacity-full`, active heading rule |
| Toolbar: 8px × 16px, bottom divider, actions at end | `space-2`, `space-4`, `border-width`, `line`; action auto margin |
| Search: 240px, decorative leading icon, named clear action inside | `search-width`; search layout and Clear search button |
| Pagination: 10px × 16px, top divider, 12px muted tabular range, compact buttons | `space-detail`, `space-4`, `border-width`, `line`, `text-small`, `muted`, `control-height-compact` |
| Composition/panels: paper, 1px line border, 6px radius | `paper`, `border-width`, `line`, `radius-panel` |
| Inspector: about 290px, canvas, left divider, 20px padding | `inspector-width`, `canvas`, `border-width`, `line`, `space-panel`; stacks in a narrow container |
| Record header: 20px padding, bottom divider, 12px muted context | `space-panel`, `border-width`, `line`, `text-small`, `muted` |
| Facts: 12px muted labels, tabular values/600, 10px pair gap | `text-small`, `muted`, `weight-emphasis`, `space-detail` |
| Focus: 3px outline and 3px offset; headings never obscure it | `focus-width`, `focus-offset`, `focus`; headings become static during keyboard interaction |
| Targets: at least 24px; coarse/narrow at least 44px | `target-size` media override and minimum dimensions, in both densities |
| Reflow at 400% zoom; navigation above content; tables scroll locally | Responsive shell and grouped navigation, zero content minimum width, overflow table region, container stacking |
