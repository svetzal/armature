# Project charter: Armature

## Purpose

Phoenix applications that grow their own atomic component libraries duplicate
the governance (levels, registries, composition rules, accessibility contracts)
and drift apart in behaviour. Armature provides that governance as a library.
It is the frame under a design system. Each consumer puts its own surface on
it.

## Scope

Armature provides:

- A level model with enforceable composition rules. The levels are tokens,
  atoms, layouts, molecules, organisms and templates. Each level composes only
  the levels beneath it.
- A registry behaviour that declares a consumer's components as data, and
  ExUnit helpers that check the registry against the code.
- A token contract: the names of the CSS custom properties that components
  use, and a base stylesheet written only in those properties.
- A small set of accessible baseline atoms, layouts and molecules.
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
the point where the public surface is stable enough for consumers outside
Mojility. Before 1.0.0, a minor version can break the public surface; the
changelog says how.

## Target users

Phoenix developers who run more than one application, want each to look like
itself, and want the same structure and accessibility behaviour underneath.
The first consumers are Mojility's systems: Bedrock, Roost, and the business
systems generated for Bedrock's customers.
