# Changelog

All notable changes to Armature are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Until 1.0.0, a minor version can change the public surface.

## [Unreleased]

### Added

- Project charter, licence and build configuration.
- Plain-data registry behaviour and node struct, pure checks over compiled-call/metadata
  snapshots, and an ExUnit case template with optional docs and test inventories.
- Compiler-resolved component-call analysis that follows private components,
  with neutral compiled fixtures and consumer-facing examples.
- Include the licence in generated documentation so the README link resolves.

### Changed

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
