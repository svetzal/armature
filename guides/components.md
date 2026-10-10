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
| `facts` | — | Labelled values in a description list. |
| `notice` | — | Static guidance or reported results with actions. |
| `table_toolbar` | `input`, `icon`, `button` | A labelled search and announced result count. |
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
| Inline sorting with faint arrow, stronger on hover/active | `.armature-sort`, `sort-opacity`, `opacity-full`, active heading rule |
| Toolbar: 8px × 16px, bottom divider, actions at end | `space-2`, `space-4`, `border-width`, `line`; action auto margin |
| Search: 240px, decorative leading icon, named clear action inside | `search-width`; search layout and Clear search button |
| Pagination: 10px × 16px, top divider, 12px muted tabular range, compact buttons | `space-detail`, `space-4`, `border-width`, `line`, `text-small`, `muted`, `control-height-compact` |
| Composition/panels: paper, 1px line border, 6px radius | `paper`, `border-width`, `line`, `radius-panel` |
| Inspector: about 290px, canvas, left divider, 20px padding | `inspector-width`, `canvas`, `border-width`, `line`, `space-panel`; stacks in a narrow container |
| Record header: 20px padding, bottom divider, 12px muted context | `space-panel`, `border-width`, `line`, `text-small`, `muted` |
| Facts: 12px muted labels, tabular values/600, 10px pair gap | `text-small`, `muted`, `weight-emphasis`, `space-detail` |
| Focus: 3px outline and 3px offset; headings never obscure it | `focus-width`, `focus-offset`, `focus`; headings become static during keyboard interaction |
| Targets: at least 24px; coarse/narrow at least 44px | `target-size` media override and minimum dimensions, in both densities |
| Reflow at 400% zoom; navigation above content; tables scroll locally | Wrapping catalogue columns, zero content minimum width, overflow table region, container stacking |
