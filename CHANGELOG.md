# Changelog

All notable changes to Armature are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Until 1.0.0, a minor version can change the public surface.

## [Unreleased]

### Added

- Mountable development catalogue through `Armature.Catalogue.Router`, with
  consumer registries, independent examples modules and LiveView-local state.
  Level-grouped navigation, directly linkable query parameters, heading focus,
  derived Uses/Used by links, component documentation and theme controls.
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
- Layered neutral light and dark token defaults, with muted success, warning
  and error hues that meet every declared contrast pair, and an accessibility base
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

### Changed

- Replace the hand-built preview with the router-mounted catalogue and move its
  synthetic record generator into the internal catalogue records module.
- Automatic theme containers follow the system preference independently of an
  ancestor's explicit theme; explicit light and dark controls still override it.

- Replace source-text alias/import resolution with expanded BEAM debug info.
  Follow private component captures and Phoenix default-attribute wrappers;
  require debug info (enabled by default in dev and test), failing clearly when
  absent. Component source files are no longer read.
- Keep the optional test inventory using compiler-resolved calls and captures.
  Migration: add `Armature.Registry.TestTracer.install()` to test/test_helper.exs
  and remove `async: true` from inventory registry cases. Mix compiles test
  files while asynchronous tests run; synchronous cases guarantee a complete
  inventory of the selected test files. Direct snapshot users must likewise
  use synchronous tests. Run the full matching suite for inventory validation.
- Preserve registry, checks, node and case APIs, including the `markup_uses/1`
  name. Snapshot `calls` now contains atom module/function identities and
  `test_source` contains the traced identity set rather than source strings.
  Code constructing snapshots directly must migrate those fields. Exact
  identities cover nested self aliases, `__MODULE__`, required aliases,
  lexical alias scopes and import filters; namesakes never receive credit.

- Permit organisms to compose distinct peer organisms for reusable sections;
  self-use remains forbidden and every other level composes strictly downward.
  Layouts use atoms only, and tokens remain outside the registry.
- Pin exact CI patch versions within the existing Elixir 1.18 / OTP 28 families
  so formatting and validation use a reproducible toolchain.
- Remove application-specific references from the charter and agent guidance.
