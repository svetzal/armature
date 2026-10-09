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
| Organisms | A self-contained section of an interface | Levels below |
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
