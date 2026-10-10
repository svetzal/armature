# Changelog

All notable changes to Armature are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Until 1.0.0, a minor version can change the public surface.

## [Unreleased]

### Added

- Application-shell template, side and grouped navigation, top bar, page heading,
  native Light/Dark/Auto theme switch, content panel and contextual eyebrow atom,
  with registered compositions, accessible names and live examples.
- Rail palette and shell measurement tokens, with text and focus contrast
  contracts verified in all six theme contexts and forced-colour support.
- Optional catalogue `:title` and level query navigation; the catalogue now uses
  the application shell, narrow-screen component picker and responsive panels.
  Component URLs, relationship links, history and inherited Auto tokens remain.
- Optional additive `class` on the link atom, preserving its baseline class so
  the shell can expose its skip link on focus.

### Fixed

- Isolate landmark-rendering catalogue examples in titled stylesheet-equipped
  documents, with native width presets and announced choices.
- Reflow shells, grouped navigation and panel tiling by their own inline size
  through container queries, including embedded and narrow previews.

### Changed

- Selectable tables now use exactly one `row_label` column button instead of a
  separate selection column. Mark a column `row_label` when migrating, including
  in `table_inspector`; keep every cell's content non-interactive. Declared
  `interactive` columns require a non-selectable table or details pattern.
  Row clicks, focus outlines, selection announcements and persistence remain.

## [0.1.0] - 2026-10-10

First release. The public surface can change in minor versions until 1.0.0.

### Added

- Contract-generated Tokens entry before Atoms in the catalogue, with colour
  swatches and server-computed contrast results in automatic and explicit light
  and dark themes, type specimens, spacing, shape and density samples.
- `Armature.Tokens.Values.read/1` and `check!/1` for shared stylesheet resolution
  and consumer contrast tests; optional catalogue `:token_stylesheets` paths
  read at request time. Document supported CSS and failure reporting.
  Contrast is checked in six contexts, because the system colour preference and
  an explicit theme are independent: an override that breaks contrast only when
  an explicit theme meets the opposite system preference now fails the check.
  Empty rules such as `:root {}` in a consumer stylesheet declare nothing.

- Optional Barlow 400/600 font stylesheet, bundled font files and SIL Open
  Font License; documented static serving and imports.
- Registered `facts` description-list molecule and compact table density,
  including rendered and token-contract regression tests.
- A drawn select chevron in token colours on a thin wrapper around the native
  select; list boxes and forced colours keep the native control. Every
  stylesheet rule now sits inside an Armature cascade layer, so consumer
  overrides always win.

- Mountable development catalogue through `Armature.Catalogue.Router`, with
  consumer registries, independent examples modules and LiveView-local state.
  Level-grouped navigation, directly linkable query parameters, heading focus,
  derived Uses/Used by links, component documentation and theme controls.
  The default Auto theme sets no attribute, so mounted components keep the
  consumer's own token overrides. No token rule targets an "auto" value.
- Baseline examples for every registered component, including validation and
  synthetic record search, sorting, pagination and retained selection. Mounting
  and examples guide, LiveView integration tests and token-only catalogue styles.

- Native data tables, labelled search toolbars, pagination, record headers and
  complementary inspectors through `Armature.Components`, with caller-owned state.
  Sort headings read as heading text with an arrow on the sorted column and a
  muted hint on other sortable columns.
- `table_inspector` at the template level, because it composes the complete
  table-and-details workflow from organisms and molecules. No composition rules change.
- Registry entries and documented dependencies for every data component, rendered
  accessibility tests and token-only table styles, including focus-safe sticky
  headings, non-colour selection cues and responsive targets in both themes.
- Preview coverage of 200 neutral synthetic records, complete-set search, text
  and numeric sorting, 10/25/50-row pages and persistent selection.

- Baseline native atoms, arrangement layouts and labelled form/notice molecules
  through `Armature.Components`, with token-only component styles, accessibility
  tests and a governed `Armature.UI.Registry` checked against the component guide.
  Add `--armature-layout-min-width` to govern responsive grid and split wrapping.
  Checkbox fields check themselves from the bound value and send `false` through
  a hidden input when unticked; a disabled checkbox sends nothing.
  A checkbox renders as a small box before its label in one row. Disabled
  buttons and form controls share one muted, dashed treatment, whatever the
  button variant. Invalid controls take a double-weight error-colour border.
- `examples/preview.exs`, a one-file browser preview of every component in its
  states with a theme switch (`elixir examples/preview.exs`).

- Plain-data `Armature.Tokens` contract with semantic roles and required WCAG
  contrast pairs, plus a generated token guide and consumer import examples.
- Layered light and dark token defaults in a warm paper and deep green palette
  with an amber focus ring and muted success, warning and error hues, all
  meeting every declared contrast pair, and an accessibility base
  stylesheet with focus, screen-reader-only, reduced-motion and forced-colour
  support, and larger control targets for coarse pointers and narrow screens.
  In forced colours, focus, selection and a focused selection use three
  distinct outline shapes, because both cues map to the same system colour.
- Contract-derived checks of actual CSS tokens, contrast in both themes,
  documentation agreement and colour literals confined to token definitions.

- Project charter, licence and build configuration.
- Plain-data registry behaviour and node struct, pure checks over compiled-call/metadata
  snapshots, and an ExUnit case template with optional docs and test inventories.
- Compiler-resolved component-call analysis that follows private components,
  with neutral compiled fixtures and consumer-facing examples.
- Include the licence in generated documentation so the README link resolves.

### Requirements and notes

- Elixir 1.15 or later and Phoenix LiveView 1.1 or later.
- Registry checks read component calls from compiled BEAM debug info, which is
  on by default in dev and test. A module without debug info fails the check
  with a message that says so.
- The optional test-coverage check needs `Armature.Registry.TestTracer.install()`
  in `test/test_helper.exs`, and the registry case that runs it must not be
  `async: true`, because Mix compiles test files while asynchronous tests run.
- Each level composes only the levels beneath it. Organisms may also use other
  organisms, never themselves. Layouts use atoms only. Tokens are CSS custom
  properties, not registry nodes.

[Unreleased]: https://github.com/svetzal/armature/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/svetzal/armature/releases/tag/v0.1.0
