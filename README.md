# Armature

The frame under a Phoenix design system.

A sculptor builds an armature before the clay goes on. Armature does the same
for Phoenix component libraries. It gives you the levels, the composition
rules, the token contract and a set of accessible baseline components. Your
application supplies the look and the components that are its own.

> **Status:** 0.1.0, early. The public surface can change between minor
> versions until 1.0.0. See [CHARTER.md](CHARTER.md) for scope.

## The level model

| Level | What it is | May use |
| --- | --- | --- |
| Tokens | Named colour, type, space and shape roles (CSS custom properties) | — |
| Atoms | One native element with one meaning | Tokens |
| Layouts | Arrangement only: stack, cluster, grid, split | Tokens, atoms |
| Molecules | A small group of atoms with one job | Levels below |
| Organisms | A self-contained section of an interface | Levels below, distinct peer organisms |
| Templates | A whole page structure | Levels below |

Armature checks these rules in your test suite, not only in documentation.

## How a consumer uses it

1. Add the dependency.
2. Set the token values in your own stylesheet. Each application looks like
   itself.
3. Declare your own components in your registry, next to the baseline ones.
4. Run the registry checks in your tests.

## Vendoring

Armature is MIT licensed. To own a frozen copy, put the source in your
repository and point the dependency at it:

```elixir
{:armature, path: "vendor/armature"}
```

Module names do not change, so your code does not change. Extend Armature
through your own modules, not by editing its source, and vendoring stays a
one-line change.

## Development

```bash
mix deps.get
mix test
mix format --check-formatted
mix credo --strict
```

## Licence

MIT. See [LICENSE.md](LICENSE.md).

## Declaring and checking a registry

Armature provides registry governance and a token stylesheet. Components come
from your application; baseline components will follow in later increments.
Implement the behaviour with plain data:

```elixir
defmodule Example.UI.Registry do
  @behaviour Armature.Registry
  alias Armature.Registry.Node

  @impl true
  def modules, do: [Example.UI.Elements, Example.UI.Compositions]

  @impl true
  def nodes do
    [
      %Node{
        id: :text,
        level: :atom,
        module: Example.UI.Elements,
        function: :text,
        purpose: "Displays a short text label."
      },
      %Node{
        id: :row,
        level: :layout,
        module: Example.UI.Compositions,
        function: :row,
        purpose: "Arranges labels in a row.",
        uses: [:text]
      }
    ]
  end
end
```

Every public Phoenix function component in `modules/0` must be declared. Ordinary exported functions and private components are not nodes.
Declare attributes or slots so Phoenix includes components in `__components__/0`.
Ids are unique atoms; uses are node ids. Levels are `:atom`, `:layout`,
`:molecule`, `:organism`, and `:template`. Tokens are not nodes. Composition
must go strictly downward; organisms may also use distinct peer organisms.
Layouts may use atoms only.

Add a test file containing:

```elixir
defmodule Example.UI.RegistryTest do
  use Armature.RegistryCase, registry: Example.UI.Registry
end
```

This generates a separate test for each structural check. Declared uses are
compared with compiler-resolved function captures in each component's BEAM
debug info. Local private components and Phoenix's generated default-attribute
wrappers are followed within the same module. Elixir resolves aliases, imports,
`require`, nested self aliases and `__MODULE__`; Armature does not parse source
or reproduce those resolution rules. Calls match exact module/function pairs,
so another module's same-named component cannot satisfy a declaration.
Unregistered calls produce violations. Phoenix.Component calls are ignored;
imported library components with builtin names still count. Dynamic dispatch
is not inferred.

Component modules **require debug info**, enabled by default in dev and test.
Missing debug info raises a diagnostic asking you to enable it and recompile.
Component source files need not be present.

Optional checks and additional builtin names can be configured:

```elixir
use Armature.RegistryCase,
  registry: Example.UI.Registry,
  extra_builtins: ["external_widget"],
  docs_path: "guides/components.md",
  test_source_glob: "test/ui/**/*_test.exs"
```

The docs check reads tables beneath `## Atoms`, `## Layouts`, `## Molecules`,
`## Organisms`, and `## Templates`. First-column backticks name node ids.
A second column can list backticked use ids separated by commas, or `—` for
no dependencies. A prose purpose column can be used instead; then only ids
and levels are checked. For example:

```markdown
## Atoms
| Component | Uses |
| --- | --- |
| `text` | — |

## Layouts
| Component | Uses |
| --- | --- |
| `row` | `text` |
```

For the optional test inventory, add this line to `test/test_helper.exs`,
before test files compile:

```elixir
Armature.Registry.TestTracer.install()
```

The tracer records compiler-resolved remote and imported function/1 calls and
captures (including HEEx calls) inside modules in matching files. Test modules
may compile in memory and do not need debug info. Missing tracer installation
raises a diagnostic naming the line to add. This inventory flags absent
identities; it does not prove that tests execute or assert the calls.

Inventory registry tests must be **synchronous**. `mix test` compiles all
selected test files before running synchronous tests, while asynchronous tests
can start during compilation. `Armature.RegistryCase` rejects `async: true`
when `:test_source_glob` is enabled. Direct calls to `snapshot/2` with that
option must also run in synchronous tests. Only files compiled in the current
run count; run the full matching suite when checking the inventory, rather than
a filtered or partitioned subset.

Both optional checks are off unless configured. Paths are relative to the
working directory; an empty test glob reports all nodes as untested.

Checks can also run without ExUnit assertions:

```elixir
snapshot = Armature.Registry.snapshot(Example.UI.Registry)
Armature.Registry.Checks.composition(snapshot) # [] when clean
Armature.Registry.Checks.markup_uses(snapshot)
```

The snapshot reads optional Markdown documentation and inspects compiled modules
and the recorded test inventory once. Each check is a
pure function of that captured data and returns tagged violation tuples.
`Armature.Registry.levels/0` lists levels in order, and
`Armature.Registry.at_level/2` selects a registry's nodes at a given level.

## Token stylesheet

Import the stylesheet into your Phoenix `assets/css/app.css`; the bundler
inlines it, so no separate static route or JavaScript is needed:

```css
@import "../../deps/armature/priv/static/armature.css";
```

For a path dependency, adjust the path to its `priv/static/armature.css`.
With Tailwind v4, keep CSS imports before other rules and retain the generated
`source(none)` and `@source` directives. Import Armature first so its layers
also precede Tailwind's layers:

```css
@import "../../deps/armature/priv/static/armature.css";
@import "tailwindcss" source(none);

@source "../css";
@source "../js";
@source "../../lib/example_web";
```

Armature uses `armature.tokens` and `armature.base` cascade layers. Set your
own values in unlayered CSS after the imports. This neutral example changes
spacing, typography and surface contrast:

```css
:root {
  --armature-font-sans: ui-sans-serif, system-ui, sans-serif;
  --armature-space-4: 1.125rem;
  --armature-ink: #181818;
  --armature-paper: #ffffff;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-armature-theme="light"]) {
    --armature-ink: #fafafa;
    --armature-paper: #181818;
  }
}

[data-armature-theme="dark"] {
  --armature-ink: #fafafa;
  --armature-paper: #181818;
}

[data-armature-theme="light"] {
  --armature-ink: #181818;
  --armature-paper: #ffffff;
}
```

Set `data-armature-theme="light"` or `data-armature-theme="dark"` on the
`html` element to choose a theme; omit it to follow the system preference.
The attribute also supports themed subtrees. Match all relevant theme selectors
in consumer overrides: unlayered root values take precedence over layered
root values, including the automatic dark theme.

The base layer provides focus rings, `.armature-sr-only`, reduced motion and
forced-colour state cues. It does not reset elements or style components.
Components use `var(--armature-...)` for their visual properties. Use both
`--armature-control-height` and `--armature-target-size` as minimum dimensions;
they rise to 44px for coarse pointers and viewports at most 40rem wide.
Preserve that minimum in consumer overrides.

[The token guide](guides/tokens.md) lists every role and required contrast pair,
generated from `Armature.Tokens`. Check those pairs in both themes whenever
you change colour values. Feedback must include text or a symbol; selected
items need a non-colour cue such as an outline, marker or label.
