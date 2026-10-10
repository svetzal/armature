# Baseline components

Import `Armature.Components` in consumer HTML helpers, excluding the built-in
link with `import Phoenix.Component, except: [link: 1]`. Load the Armature stylesheet
and override its tokens in your own CSS. Components share light and dark token values.

## Atoms

| Component | Uses | Purpose |
| --- | --- | --- |
| `button` | — | A named native action. |
| `link` | — | A named navigation link. |
| `icon` | — | Decorative consumer SVG. |
| `input` | — | A native single-line control. |
| `select` | — | A native option control. |
| `textarea` | — | A native multiline control. |
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
| `field` | `input`, `select`, `textarea` | A labelled control with hint and validation. |
| `notice` | — | Static guidance or reported results with actions. |
| `table_toolbar` | `input` | A labelled search and announced result count. |
| `pagination` | `button`, `select` | Named paging controls and an announced range. |
| `record_header` | `status` | A record heading with context and actions. |

## Organisms

| Component | Uses | Purpose |
| --- | --- | --- |
| `data_table` | — | A sortable native table with named record selection. |
| `inspector` | — | A named complementary details landmark. |

## Templates

| Component | Uses | Purpose |
| --- | --- | --- |
| `table_inspector` | `link`, `split`, `table_toolbar`, `data_table`, `pagination`, `inspector` | A complete table and supporting details workflow. |

Tables are checked against `Armature.UI.Registry` by the test suite.

## Controls and validation

`button` defaults to `type="button"`; use `type="submit"` explicitly in forms.
`link` forwards Phoenix's `navigate`, `patch` and `href` behavior. Native controls
preserve browser keyboard behavior. Standalone input, select and textarea atoms
need a caller-owned visible label or `aria-label`. Use `field` for a visible label,
optional hint and errors bound to the control by stable ids.

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

## Feedback

`status` labels must express meaning in words, such as "Complete" or "Needs review".
Tones are `neutral`, `success`, `warning` and `error`. `icon` always hides its inline
SVG slot from assistive technology; keep accessible names on the surrounding control.
Supply only decorative, noninteractive SVG content.

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
`sort_direction` (`"asc"` or `"desc"`). Sticky headings return to normal flow
while the scroll region contains focus, so they cannot cover a keyboard target.

Supply `select_event` and the id of an existing inspector to enable selection.
Each button sends `%{"id" => row_id}` and includes that identifier in its name;
`aria-pressed` and the visible word "Selected" identify the selected record.
The default `row_id` reads `row.id`; override it with a function returning a
unique, DOM-safe identifier. Match `selected_id` to that function's return type.
Selection does not move focus. Column content may contain other native controls;
the table does not attach click handlers to entire rows.

`table_toolbar` renders a labelled search form sending `%{"query" => query}`
to `search_event` on change or submit, an atomic polite result count from `total`,
and an optional `actions` slot. Searching is always the caller's responsibility.
`pagination` receives `page`, `pages`, `first`, `last`, `total` and `page_event`;
its named buttons send `%{"page" => page}` and disable at the boundaries. For
an empty result set pass page 1 of 1 and range 0–0. Supplying `page_sizes` and
`size_event` adds a labelled select sending `%{"page_size" => size}`. Its range
is an atomic polite status, with grouping separators, such as "26–50 of 2,000".
Phoenix delivers these event values as strings.

`inspector` is an `aside` named by its heading, with a stable `id` and
`tabindex="-1"` for skip-link access. It is never a live region. `record_header`
provides an h2, optional `context`, optional status in words and `actions`.

`table_inspector` is a **template**: it composes the complete data browsing
workflow rather than one semantic unit. It uses `split` to place the inspector
beside the table when there is room, then below it as the regions wrap. It
forwards the `col` slots, renders `actions` in the toolbar and `details` inside
the inspector. IDs derive from the template id, keeping the selection buttons'
`aria-controls` and skip link connected to the actual landmark. Update
`selection_label` when selection changes; only this short status is announced,
without moving focus or announcing all details. Keep selection outside the
filtered and paged collection so it survives those operations.

```heex
<.table_inspector id="records" rows={@rows} caption="Example records"
  query={@query} search_event="search" total={@total}
  sort_by={@sort_by} sort_direction={@sort_direction} sort_event="sort"
  selected_id={@selected_id} select_event="select"
  selection_label={@selection_label} inspector_title="Record details"
  page={@page} pages={@pages} first={@first} last={@last} page_event="page"
  page_sizes={[10, 25, 50]} page_size={@page_size} size_event="size">
  <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
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

`examples/preview.exs` demonstrates this contract with 200 generated records,
search across the complete set, text and numeric sorting, 10/25/50 page sizes,
and selection retained across search and paging. Its theme controls exercise
the same table, hover, selected and focus tokens in light and dark modes.
