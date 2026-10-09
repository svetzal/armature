# Armature agent guidance

Why this project exists and what it will and won't do: @CHARTER.md

**Agent**: elixir-phoenix-craftsperson

## What this library is

Armature governs the structure of a Phoenix component library. Consumers
supply the look (token values) and their own components (registered
extensions). Read the charter's non-goals before you add anything. The test
for a new public function or component is: would an unrelated Phoenix
application want it? If not, it belongs in a consumer.

## The level model

The levels are tokens, atoms, layouts, molecules, organisms and templates, in
that order. Each level composes only the levels beneath it. Layouts arrange
and carry no meaning of their own. Do not add a level, rename one, or relax a
composition rule without a changelog entry that says why.

## Rules for the code

- Components are Phoenix function components with `attr` and `slot`
  declarations. No macros that generate components; a reader must be able to
  jump from a call to its definition.
- Components style themselves only through the token contract (CSS custom
  properties). No hard-coded colours, sizes or fonts. No Tailwind classes in
  library markup; consumers may or may not use Tailwind.
- Native elements first. Every control has an accessible name. State is never
  shown by colour alone. Target WCAG 2.2 AA.
- No consumer names, brands or business terms in this repository. Examples use
  neutral synthetic content.
- Keep the public surface small. Anything public is a semver commitment.

## Versioning and releases

Semantic versioning, starting at 0.1.0. Version 1.0.0 is the signal that the
public surface is stable enough for consumers outside Mojility. Before 1.0.0,
a minor version can break the public surface, and its changelog entry says
how to migrate. Record every change under `## [Unreleased]` in
`CHANGELOG.md`. Publishing to Hex needs Stacey's approval.

## Quality gates

Run all of these before you commit. All must pass.

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix test --cover
mix deps.audit
```

## Git

Trunk-based. Commit to `main` and push. No branches, no pull requests.
