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
