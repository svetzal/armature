defmodule Armature.Tokens.ValuesTest do
  use ExUnit.Case, async: true
  alias Armature.Tokens.Values

  setup do
    directory =
      Path.join(System.tmp_dir!(), "armature-tokens-#{System.unique_integer([:positive])}")

    File.mkdir_p!(directory)
    on_exit(fn -> File.rm_rf!(directory) end)
    {:ok, stylesheet: Path.join(directory, "tokens.css")}
  end

  test "an explicit theme is checked under the opposite system preference", %{stylesheet: path} do
    # Only the combination "explicit Light while the system prefers dark"
    # breaks contrast here; it must not pass unnoticed.
    File.write!(path, """
    @media (prefers-color-scheme: dark) {
      [data-armature-theme="light"] { --armature-ink: #fffefb; }
    }
    """)

    results = Values.read([path])
    failing = &Enum.reject(results[&1].pairs, fn pair -> pair.pass? end)

    assert failing.(:explicit_light_on_dark_system) != []
    assert failing.(:explicit_light) == []
    assert failing.(:light) == []
    assert failing.(:dark) == []

    error = assert_raise ArgumentError, fn -> Values.check!([path]) end
    assert error.message =~ "explicit_light_on_dark_system: --armature-ink on --armature-paper"
  end

  test "every context is evaluated and labelled" do
    assert Values.read() |> Map.keys() |> Enum.sort() ==
             Values.contexts() |> Keyword.keys() |> Enum.sort()

    assert Values.contexts()[:explicit_dark_on_light_system] == "Dark (explicit, system light)"
  end

  test "empty rules declare nothing and do not stop evaluation", %{stylesheet: path} do
    File.write!(path, ":root {}\n@media (prefers-color-scheme: dark) { :root {} }\n")
    assert Values.read([path]).light.values == Values.read().light.values
    assert :ok = Values.check!([path])
  end

  test "contrast uses WCAG relative luminance", %{stylesheet: path} do
    for {foreground, background, expected} <- [
          {"#000000", "#ffffff", 21.0},
          {"#ffffff", "#000000", 21.0},
          {"#777777", "#777777", 1.0},
          {"#777777", "#ffffff", 4.478}
        ] do
      File.write!(
        path,
        ":root { --armature-ink: #{foreground}; --armature-paper: #{background}; }"
      )

      pair =
        Enum.find(
          Values.read([path]).light.pairs,
          &(&1.foreground == "--armature-ink" and &1.background == "--armature-paper")
        )

      assert_in_delta pair.ratio, expected, 0.001
    end
  end

  test "defaults resolve every contract token and pass all four themes" do
    results = Values.read()
    names = Enum.map(Armature.Tokens.all(), & &1.name) |> Enum.sort()

    for {_theme, result} <- results do
      assert Enum.sort(Map.keys(result.values)) == names
      assert Enum.all?(result.pairs, & &1.pass?)
      assert Enum.all?(result.pairs, &is_float(&1.ratio))
    end

    assert :ok = Values.check!()
    assert results.light.values["--armature-ink"] != results.dark.values["--armature-ink"]
    assert results.light.values == results.explicit_light.values
    assert results.dark.values == results.explicit_dark.values
  end

  test "consumer root overrides affect automatic themes and explicit overrides affect containers",
       %{stylesheet: path} do
    File.write!(path, """
    :root { --armature-ink: #fff; --armature-paper: #ffffff; }
    @media (prefers-color-scheme: dark) {
      :root { --armature-ink: #000; --armature-paper: #000000; }
    }
    [data-armature-theme="light"] { --armature-ink: rgb(255 255 255); --armature-paper: #fff; }
    [data-armature-theme="dark"] { --armature-ink: rgb(0%, 0%, 0%); --armature-paper: #000; }
    """)

    for {_theme, result} <- Values.read([path]) do
      pair =
        Enum.find(
          result.pairs,
          &(&1.foreground == "--armature-ink" and &1.background == "--armature-paper")
        )

      assert pair.ratio == 1.0
      refute pair.pass?
      assert pair.minimum == 4.5
    end

    assert_raise ArgumentError,
                 ~r/light: --armature-ink on --armature-paper: 1.0:1, requires 4.5:1/,
                 fn -> Values.check!([path]) end
  end

  test "root inheritance does not override a declaration on an explicit container", %{
    stylesheet: path
  } do
    File.write!(path, ":root { --armature-ink: #ffffff; }")
    results = Values.read([path])
    assert results.light.values["--armature-ink"] == "#ffffff"

    assert results.explicit_light.values["--armature-ink"] ==
             Values.read().light.values["--armature-ink"]
  end

  test "layers, importance, specificity and source order follow the cascade", %{stylesheet: path} do
    File.write!(path, """
    @layer first, second;
    @layer first { :root { --armature-paper: #123456 !important; --armature-ink: #111111; } }
    @layer second { :root { --armature-paper: #abcdef !important; --armature-ink: #222222; } }
    :root { --armature-paper: #ffffff; --armature-ink: #333333; --armature-ink: #000000; }
    :root, [data-armature-theme="light"] { --armature-space-4: 2rem; }
    [data-armature-theme] { --armature-space-4: 3rem; }
    @media (forced-colors: active) { :root { --armature-ink: CanvasText; } }
    """)

    results = Values.read([path])
    assert results.light.values["--armature-paper"] == "#123456"
    assert results.light.values["--armature-ink"] == "#000000"
    assert results.explicit_light.values["--armature-space-4"] == "3rem"
  end

  test "layers retain their first occurrence order and root theme selectors need an attribute", %{
    stylesheet: path
  } do
    File.write!(path, """
    @layer early { :root { --armature-space-4: 2rem; } }
    @layer late, early;
    @layer late { :root { --armature-space-4: 3rem; } }
    :root[data-armature-theme="dark"] { --armature-ink: #ffffff; }
    [data-armature-theme=dark] { --armature-space-4: 4rem; }
    """)

    results = Values.read([path])
    assert results.light.values["--armature-space-4"] == "3rem"
    assert results.explicit_dark.values["--armature-space-4"] == "4rem"
    assert results.dark.values["--armature-ink"] == Values.read().dark.values["--armature-ink"]
  end

  test "inherited variables are computed before container overrides", %{stylesheet: path} do
    File.write!(path, """
    :root { --custom-colour: var(--armature-paper); }
    [data-armature-theme="light"] { --armature-ink: var(--custom-colour); --armature-paper: #000; }
    """)

    result = Values.read([path]).explicit_light
    assert result.values["--armature-ink"] == "#fffefb"
    assert result.values["--armature-paper"] == "#000"
  end

  test "variables and fallbacks resolve and missing or unsupported colours fail visibly", %{
    stylesheet: path
  } do
    File.write!(path, """
    :root {
      --custom-colour: #123456;
      --armature-ink: var(--custom-colour);
      --armature-paper: var(--missing, #fff);
      --armature-muted: oklch(50% 0.1 120);
      --armature-focus: var(--cycle);
      --cycle: var(--cycle);
    }
    """)

    result = Values.read([path]).light
    assert result.values["--armature-ink"] == "#123456"
    assert result.values["--armature-paper"] == "#fff"
    assert Enum.any?(result.pairs, &(&1.ratio == nil and not &1.pass?))

    assert_raise ArgumentError, ~r/Unsupported or unresolved colour/, fn ->
      Values.check!([path])
    end
  end

  test "stylesheets are re-read and later files win", %{stylesheet: path} do
    File.write!(path, ":root { --armature-space-4: 2rem; }")
    assert Values.read([path]).light.values["--armature-space-4"] == "2rem"
    second = path <> ".css"
    File.write!(second, ":root { --armature-space-4: 3rem; }")
    assert Values.read([path, second]).light.values["--armature-space-4"] == "3rem"
    File.write!(second, ":root { --armature-space-4: 4rem; }")
    assert Values.read([path, second]).light.values["--armature-space-4"] == "4rem"
  end
end
