defmodule Armature.Tokens.ValuesTest do
  use ExUnit.Case, async: true
  alias Armature.Tokens.Values

  @defaults File.read!(Path.expand("../priv/static/armature.css", __DIR__))
  @external_resource Path.expand("../priv/static/armature.css", __DIR__)

  test "evaluates a stylesheet string without touching the filesystem" do
    assert evaluate(":root { --armature-space-4: 3rem; }").light.values["--armature-space-4"] ==
             "3rem"
  end

  test "an explicit theme is checked under the opposite system preference" do
    # Only the combination "explicit Light while the system prefers dark"
    # breaks contrast here; it must not pass unnoticed.
    results =
      evaluate("""
      @media (prefers-color-scheme: dark) {
        [data-armature-theme="light"] { --armature-ink: #fffefb; }
      }
      """)

    failing = &Enum.reject(results[&1].pairs, fn pair -> pair.pass? end)

    assert failing.(:explicit_light_on_dark_system) != []
    assert failing.(:explicit_light) == []
    assert failing.(:light) == []
    assert failing.(:dark) == []
  end

  test "every context is evaluated" do
    assert Values.read() |> Map.keys() |> Enum.sort() ==
             Values.contexts() |> Keyword.keys() |> Enum.sort()
  end

  test "each context carries a readable label" do
    assert Values.contexts()[:explicit_dark_on_light_system] == "Dark (explicit, system light)"
  end

  @empty_rules ":root {}\n@media (prefers-color-scheme: dark) { :root {} }\n"

  test "empty rules declare nothing" do
    assert evaluate(@empty_rules).light.values == Values.evaluate(@defaults).light.values
  end

  test "empty rules do not stop evaluation" do
    for {_context, result} <- evaluate(@empty_rules) do
      assert Enum.all?(result.pairs, & &1.pass?)
    end
  end

  test "contrast uses WCAG relative luminance" do
    for {foreground, background, expected} <- [
          {"#000000", "#ffffff", 21.0},
          {"#ffffff", "#000000", 21.0},
          {"#777777", "#777777", 1.0},
          {"#777777", "#ffffff", 4.478}
        ] do
      pair =
        ink_on_paper(
          evaluate(":root { --armature-ink: #{foreground}; --armature-paper: #{background}; }").light
        )

      assert_in_delta pair.ratio, expected, 0.001
    end
  end

  test "defaults resolve every contract token in every context" do
    names = Enum.map(Armature.Tokens.all(), & &1.name) |> Enum.sort()

    for {_theme, result} <- Values.read() do
      assert Enum.sort(Map.keys(result.values)) == names
    end
  end

  test "defaults pass every contrast pair in every context" do
    for {_theme, result} <- Values.read() do
      assert Enum.all?(result.pairs, & &1.pass?)
      assert Enum.all?(result.pairs, &is_float(&1.ratio))
    end

    assert :ok = Values.check!()
  end

  test "default light ink differs from default dark ink" do
    results = Values.read()
    assert results.light.values["--armature-ink"] != results.dark.values["--armature-ink"]
  end

  test "explicit themes default to the automatic theme values" do
    results = Values.read()
    assert results.light.values == results.explicit_light.values
    assert results.dark.values == results.explicit_dark.values
  end

  test "consumer root overrides set the automatic theme values" do
    results =
      evaluate("""
      :root { --armature-ink: #fff; --armature-paper: #ffffff; }
      @media (prefers-color-scheme: dark) {
        :root { --armature-ink: #000; --armature-paper: #000000; }
      }
      """)

    for theme <- [:light, :dark] do
      assert %{ratio: 1.0, pass?: false, minimum: 4.5} = ink_on_paper(results[theme])
    end
  end

  test "explicit theme overrides set the theme container values" do
    results =
      evaluate("""
      [data-armature-theme="light"] { --armature-ink: rgb(255 255 255); --armature-paper: #fff; }
      [data-armature-theme="dark"] { --armature-ink: rgb(0%, 0%, 0%); --armature-paper: #000; }
      """)

    for {theme, _label} <- Values.contexts(),
        String.starts_with?(Atom.to_string(theme), "explicit_") do
      assert %{ratio: 1.0, pass?: false, minimum: 4.5} = ink_on_paper(results[theme])
    end
  end

  test "a failing check reports the pair ratio against its requirement" do
    path = tmp_stylesheet(":root { --armature-ink: #fff; --armature-paper: #ffffff; }")

    assert_raise ArgumentError,
                 ~r/light: --armature-ink on --armature-paper: 1.0:1, requires 4.5:1/,
                 fn -> Values.check!([path]) end
  end

  test "root inheritance does not override a declaration on an explicit container" do
    results = evaluate(":root { --armature-ink: #ffffff; }")
    assert results.light.values["--armature-ink"] == "#ffffff"

    assert results.explicit_light.values["--armature-ink"] ==
             Values.evaluate(@defaults).light.values["--armature-ink"]
  end

  @cascade """
  @layer first, second;
  @layer first { :root { --armature-paper: #123456 !important; --armature-ink: #111111; } }
  @layer second { :root { --armature-paper: #abcdef !important; --armature-ink: #222222; } }
  :root { --armature-paper: #ffffff; --armature-ink: #333333; --armature-ink: #000000; }
  :root, [data-armature-theme="light"] { --armature-space-4: 2rem; }
  [data-armature-theme] { --armature-space-4: 3rem; }
  @media (forced-colors: active) { :root { --armature-ink: CanvasText; } }
  """

  test "an important declaration in the earliest layer wins" do
    assert evaluate(@cascade).light.values["--armature-paper"] == "#123456"
  end

  test "the last unlayered declaration beats layered declarations" do
    assert evaluate(@cascade).light.values["--armature-ink"] == "#000000"
  end

  test "a later rule of equal specificity wins on an explicit container" do
    assert evaluate(@cascade).explicit_light.values["--armature-space-4"] == "3rem"
  end

  @layer_order """
  @layer early { :root { --armature-space-4: 2rem; } }
  @layer late, early;
  @layer late { :root { --armature-space-4: 3rem; } }
  :root[data-armature-theme="dark"] { --armature-ink: #ffffff; }
  [data-armature-theme=dark] { --armature-space-4: 4rem; }
  """

  test "layers keep the order of their first occurrence" do
    assert evaluate(@layer_order).light.values["--armature-space-4"] == "3rem"
  end

  test "a root theme selector does not apply to the automatic theme" do
    assert evaluate(@layer_order).dark.values["--armature-ink"] ==
             Values.evaluate(@defaults).dark.values["--armature-ink"]
  end

  test "an unquoted theme attribute selector matches its container" do
    assert evaluate(@layer_order).explicit_dark.values["--armature-space-4"] == "4rem"
  end

  test "inherited variables are computed before container overrides" do
    result =
      evaluate("""
      :root { --custom-colour: var(--armature-paper); }
      [data-armature-theme="light"] { --armature-ink: var(--custom-colour); --armature-paper: #000; }
      """).explicit_light

    assert result.values["--armature-ink"] == "#fffefb"
    assert result.values["--armature-paper"] == "#000"
  end

  @references """
  :root {
    --custom-colour: #123456;
    --armature-ink: var(--custom-colour);
    --armature-paper: var(--missing, #fff);
    --armature-muted: oklch(50% 0.1 120);
    --armature-focus: var(--cycle);
    --cycle: var(--cycle);
  }
  """

  test "a variable reference resolves to its value" do
    assert evaluate(@references).light.values["--armature-ink"] == "#123456"
  end

  test "a missing variable falls back to its fallback value" do
    assert evaluate(@references).light.values["--armature-paper"] == "#fff"
  end

  test "an unresolvable colour fails its pair without a ratio" do
    assert Enum.any?(evaluate(@references).light.pairs, &(&1.ratio == nil and not &1.pass?))
  end

  test "an unsupported or unresolved colour is named in its pair error" do
    errors = for pair <- evaluate(@references).light.pairs, pair.error, do: pair.error
    assert Enum.any?(errors, &(&1 =~ "Unsupported or unresolved colour"))
  end

  test "later stylesheets win over earlier ones" do
    first = tmp_stylesheet(":root { --armature-space-4: 2rem; }")
    second = tmp_stylesheet(":root { --armature-space-4: 3rem; }")
    assert Values.read([first, second]).light.values["--armature-space-4"] == "3rem"
  end

  test "stylesheets are re-read on every call" do
    path = tmp_stylesheet(":root { --armature-space-4: 2rem; }")
    assert Values.read([path]).light.values["--armature-space-4"] == "2rem"
    File.write!(path, ":root { --armature-space-4: 4rem; }")
    assert Values.read([path]).light.values["--armature-space-4"] == "4rem"
  end

  defp evaluate(css), do: Values.evaluate(@defaults <> "\n" <> css)

  defp tmp_stylesheet(css) do
    path =
      Path.join(System.tmp_dir!(), "armature-tokens-#{System.unique_integer([:positive])}.css")

    File.write!(path, css)
    on_exit(fn -> File.rm(path) end)
    path
  end

  defp ink_on_paper(result) do
    Enum.find(
      result.pairs,
      &(&1.foreground == "--armature-ink" and &1.background == "--armature-paper")
    )
  end
end
