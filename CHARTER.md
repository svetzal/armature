# Project charter: Armature

## Purpose

Phoenix applications that grow their own atomic component libraries duplicate
the governance (levels, registries, composition rules, accessibility contracts)
and drift apart in behaviour and in quality. Armature provides that governance
as a library, together with components built to a high standard of
accessibility and craft. It is the frame under a design system. Each consumer
puts its own surface on it.

## Design goals

These goals bind every component, every release and every contribution. A
change that trades one of them away for speed is not finished.

### 1. Accessible as a foundation

Accessibility is designed in from the first line of a component, never added
afterwards. A component without its accessibility contract and the tests that
hold it is not done.

- WCAG 2.2 AA is the floor for every component in every theme. Where a AAA
  criterion applies and meeting it costs design effort rather than function,
  meet it: enhanced contrast, 44 by 44 pixel targets and a strong, unobscured
  focus indicator.
- Native HTML elements first. Keyboard use has the same reach as pointer use.
  Every control has an accessible name, and every state (selected, invalid,
  disabled, busy) is exposed to assistive technology.
- Meaning never rests on colour alone. Layouts reflow at 400% zoom, and
  components respect reduced motion and forced colours.
- Evidence comes in layers: automated tests for semantics, browser checks for
  focus and visual state, and walkthroughs with screen readers before 1.0.0.

### 2. Decomposable and recomposable

Armature follows atomic design. Every component is built from components at
lower levels, and every composition can be taken apart into its parts and put
back together in a new way.

- A consumer can compose new molecules, organisms and templates from the same
  parts the baseline uses, and can replace one part without forking the rest.
- The registry makes the composition graph explicit, and its checks prove the
  graph matches the code.
- Layouts arrange and carry no meaning or styling, so moving content between
  arrangements never changes how it looks or behaves.
- Each component owns one job. State that belongs to the application (data,
  sort order, selection, pages) stays with the application.

### 3. Refined by default

A consumer that sets only its brand colours gets an interface that looks
finished. Armature sets a high visual standard, not a starting point to be
polished later.

- A compact, readable type scale and consistent density, with a compact mode
  for data-heavy screens.
- Considered surfaces: panels, dividers and insets that show structure without
  noise.
- Every state is designed: hover, focus, active, selected, disabled, invalid,
  empty, loading and error.
- Interaction details get the same care as layout: sort affordances, selection
  cues, inline validation, result announcements and focus recovery.
- Quality is judged by eye in a browser, in both themes and at narrow widths,
  through the catalogue. Passing tests is necessary but not sufficient.

### 4. Interactive where it serves the task

Interactions use Phoenix LiveView, with state owned by the server. Sorting,
filtering, paging, selection and validation respond immediately and announce
their results. Armature adds no JavaScript framework. A small hook is
acceptable only where native elements and LiveView cannot provide the
behaviour, and it must keep keyboard and assistive-technology parity.

## Future direction: domain-informed forms

The data a form captures should shape the form. A later phase will explore how
a domain model (types, constraints, required fields, cardinality and references
between entities) can inform form design: which control fits a value, how
fields group, how validation reads, and how a person chooses a related record.
The aim is a form that follows from its model rather than one assembled by hand.

This phase has not started and nothing in it is in scope yet. This section
exists so that current work does not block it: fields accept Phoenix form
fields, each control has a type, and validation stays bound to the field it
explains. Armature will not encode a particular business's domain. A mapping
from model to form will be generic.

## Scope

Armature provides:

- A level model with enforceable composition rules. The levels are tokens,
  atoms, layouts, molecules, organisms and templates. Each level composes only
  the levels beneath it, except organisms may use distinct peer organisms.
- A registry behaviour that declares a consumer's components as data, and
  ExUnit helpers that check the registry against the code.
- A token contract: the names of the CSS custom properties that components
  use, and a base stylesheet written only in those properties.
- A baseline set of accessible, refined components at every level, from atoms
  to templates.
- A development catalogue that a consumer mounts in its router. It renders
  that consumer's own registry: the baseline and its extensions together.

Consumers supply their visual identity through token values. They supply their
own components and compositions through registered extensions.

## Non-goals

- Product themes or brand identity for any consumer.
- Business compositions (a quote form, an inventory table, a booking agenda).
- A page-composition language or scene renderer.
- A requirement for Tailwind or a JavaScript framework.

## Distribution

Armature is released under the MIT licence on Hex. A consumer can vendor it as
a path dependency without code changes:

```elixir
{:armature, path: "vendor/armature"}
```

This only stays a one-line change while consumers extend Armature through its
public surface and do not edit its source.

## Versioning

Armature follows semantic versioning. It starts at 0.1.0. Version 1.0.0 marks
the point where the public surface is stable enough for external consumers.
Before 1.0.0, a minor version can break the public surface, and the changelog
says how to migrate. Version 1.0.0 also requires the screen-reader walkthroughs
named in the accessibility goal.

## Target users

Phoenix developers who run more than one application, want each to look like
itself, and want the same structure and accessibility behaviour underneath.
Registries and examples use neutral content and remain application independent.
