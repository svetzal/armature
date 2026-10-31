defmodule Armature.TokensTest do
  use ExUnit.Case, async: true

  import Armature.CssGuards, only: [colour_literal?: 1]

  alias Armature.Tokens
  alias Armature.Tokens.Values

  @stylesheet Path.expand("../priv/static/armature.css", __DIR__)
  @guide Path.expand("../guides/tokens.md", __DIR__)

  setup do
    css = File.read!(@stylesheet)

    rules = Values.rules(css)

    {:ok, css: css, rules: rules}
  end

  test "contract token names are unique armature-prefixed custom properties" do
    names = Enum.map(Tokens.all(), & &1.name)

    assert names == Enum.uniq(names)
    assert Enum.all?(names, &String.starts_with?(&1, "--armature-"))
  end

  test "every contract token belongs to a known group" do
    for token <- Tokens.all() do
      assert token.group in [:colour, :typography, :space, :shape, :motion, :control]
    end
  end

  test "every contract token role is a sentence ending in a period" do
    for token <- Tokens.all() do
      assert String.ends_with?(token.role, ".")
    end
  end

  test "colour contrast references name colour tokens at a known WCAG ratio" do
    tokens = Tokens.all()

    for token <- tokens, token.group == :colour do
      assert is_list(token.contrast)

      for pair <- token.contrast do
        assert Enum.any?(tokens, &(&1.name == pair.background and &1.group == :colour))
        assert pair.ratio in [3, 4.5]
      end
    end
  end

  test "every theme selector defines exactly the contract", %{rules: rules} do
    expected = Tokens.all() |> Enum.map(& &1.name) |> Enum.sort()

    for selector <- theme_selectors() do
      values = rule!(rules, selector)
      names = Enum.map(values, &elem(&1, 0))
      assert Enum.sort(names) == expected, "Token mismatch in #{selector}"
    end
  end

  test "explicit dark theme equals automatic dark theme", %{rules: rules} do
    assert rule!(rules, "[data-armature-theme=\"dark\"]") ==
             rule!(rules, ":root:where(:not([data-armature-theme=\"light\"]))")
  end

  test "explicit light theme equals root", %{rules: rules} do
    assert rule!(rules, ":root") ==
             rule!(rules, "[data-armature-theme=\"light\"]")
  end

  test "every custom property named in the stylesheet belongs to the contract", %{css: css} do
    expected = MapSet.new(Tokens.all(), & &1.name)
    names = Regex.scan(~r/--[a-z][\w-]*/, css) |> List.flatten() |> MapSet.new()
    assert names == expected
  end

  test "actual theme colour values meet every declared WCAG contrast pair" do
    assert :ok = Values.check!()
  end

  test "colour literals appear only in colour token definitions", %{css: css} do
    colour_names = Tokens.all() |> Enum.filter(&(&1.group == :colour)) |> Enum.map(& &1.name)
    without_comments = Regex.replace(~r{/\*.*?\*/}s, css, "")

    for [_, name, value] <- Regex.scan(~r/(--[\w-]+)\s*:\s*([^;{}]+);/, without_comments),
        colour_literal?(value) do
      assert name in colour_names, "Colour literal in #{name}"
    end

    outside_definitions =
      Regex.replace(~r/--armature-[\w-]+\s*:\s*[^;{}]+;/, without_comments, "")

    refute colour_literal?(outside_definitions)
  end

  test "colour guard detects every literal syntax without confusing identifiers" do
    for value <- [
          "#abc",
          "#aabbcc",
          "#aabbccdd",
          "rgb(1 2 3)",
          "rgba(1, 2, 3, 0.5)",
          "hsl(0 0% 50%)",
          "hsla(0, 0%, 50%, 0.5)",
          "oklch(0.5 0 0)",
          "rebeccapurple",
          "CanvasText",
          "currentColor"
        ] do
      assert colour_literal?("outline: 1px solid #{value};"), "Missed #{value}"
    end

    refute colour_literal?("white-space: nowrap; outline: var(--armature-focus);")
    refute colour_literal?(".red-label { font-family: \"Black\"; }")
  end

  describe "base layer" do
    setup %{css: css} do
      [_, base] = String.split(css, "@layer armature.base {")
      {:ok, base: base}
    end

    test "defines no custom properties", %{base: base} do
      refute Regex.match?(~r/--[\w-]+\s*:/, base)
    end

    test "uses declared variables instead of literal dimensions or durations", %{base: base} do
      declarations = Regex.replace(~r/@(?:media|container)[^{]+\{/, base, "")
      refute Regex.match?(~r/\b\d*\.?\d+(?:px|rem|em|ms|s|%)\b/, declarations)
    end
  end

  describe "component layer" do
    setup %{css: css} do
      [_, components] = String.split(css, "@layer armature.components {")
      {:ok, components: components}
    end

    test "contains no colour literals", %{components: components} do
      refute colour_literal?(components)
    end

    test "defines no custom properties", %{components: components} do
      refute Regex.match?(~r/--[\w-]+\s*:/, components)
    end

    test "uses declared variables instead of literal dimensions or durations", %{
      components: components
    } do
      # Breakpoints cannot consume CSS custom properties; declarations still must.
      declarations = Regex.replace(~r/@(?:media|container)[^{]+\{/, components, "")
      refute Regex.match?(~r/\b\d*\.?\d+(?:px|rem|em|ms|s)\b/, declarations)
    end

    test "applies the accent tokens", %{components: components} do
      assert components =~ "color: var(--armature-on-accent)"
      assert components =~ "background: var(--armature-accent)"
    end

    test "applies the status tone tokens", %{components: components} do
      for tone <- ~w(success warning error) do
        assert components =~ "color: var(--armature-#{tone}-emphasis)"
        assert components =~ "background: var(--armature-#{tone}-bg)"
      end
    end

    test "layouts declare no colour border or background", %{components: components} do
      for [_, declarations] <-
            Regex.scan(~r/\.armature-(?:stack|cluster|grid|split)[^{]*\{([^}]+)\}/, components) do
        refute declarations =~ "color"
        refute declarations =~ "border"
        refute declarations =~ "background"
      end
    end
  end

  test "theme selectors preserve cascade order", %{css: css, rules: rules} do
    assert css =~ "@layer armature.tokens, armature.base, armature.components;"
    selectors = Enum.map(rules, &elem(&1, 0))
    positions = Enum.map(theme_selectors(), &Enum.find_index(selectors, fn s -> s == &1 end))
    assert Enum.sort(positions) == positions
  end

  test "automatic theme inherits root token overrides", %{css: css} do
    # "Auto" follows the page. A token rule on any auto container would sit on
    # a descendant and hide the consumer's :root overrides inside it.
    refute css =~ ~s([data-armature-theme="auto"])
  end

  describe "evaluated theme contexts" do
    setup do
      {:ok, contexts: Values.read()}
    end

    test "six contexts are evaluated", %{contexts: contexts} do
      assert map_size(contexts) == 6
    end

    test "the rail surface keeps its reference value in every context", %{contexts: contexts} do
      for {_context, result} <- contexts do
        assert result.values["--armature-rail-surface"] == "#173c32"
      end
    end

    test "all five rail contrast pairs pass in every context", %{contexts: contexts} do
      for {_context, result} <- contexts do
        rail_pairs =
          Enum.filter(result.pairs, &String.starts_with?(&1.foreground, "--armature-rail-"))

        assert length(rail_pairs) == 5
        assert Enum.all?(rail_pairs, & &1.pass?)
      end
    end

    test "rail geometry keeps its documented widths in every context", %{contexts: contexts} do
      for {_context, result} <- contexts do
        assert result.values["--armature-rail-width"] == "210px"
        assert result.values["--armature-rail-width-narrow"] == "155px"
        assert result.values["--armature-nav-width"] == "190px"
      end
    end
  end

  test "guide table is generated from the contract" do
    guide = File.read!(@guide)
    [_, generated] = String.split(guide, "<!-- tokens:start -->\n")
    [table, _] = String.split(generated, "<!-- tokens:end -->")
    assert table == Tokens.markdown_table()
  end

  test "root token values match the reference", %{rules: rules} do
    values = rules |> rule!(":root") |> Map.new()

    for {name, value} <- [
          {"text-base", "0.875rem"},
          {"text-control", "0.8125rem"},
          {"text-small", "0.75rem"},
          {"text-micro", "0.6875rem"},
          {"text-heading", "1.25rem"},
          {"line-height", "1.5"},
          {"weight-emphasis", "600"},
          {"control-height", "36px"},
          {"control-height-compact", "32px"},
          {"radius-base", "0.3125rem"},
          {"radius-panel", "0.375rem"},
          {"radius-small", "0.25rem"},
          {"focus-width", "3px"},
          {"focus-offset", "3px"},
          {"table-cell-padding", "0.75rem 1rem"},
          {"table-cell-padding-compact", "0.375rem 1rem"},
          {"table-row-height", "44px"},
          {"table-row-height-compact", "34px"},
          {"search-width", "15rem"},
          {"inspector-width", "18.125rem"}
        ] do
      assert values["--armature-" <> name] == value
    end

    assert values["--armature-font-sans"] == ~s("Barlow", system-ui, sans-serif)
  end

  test "the shipped stylesheet carries no catalogue presentation", %{css: css} do
    refute css =~ "catalogue"
  end

  test "the shipped stylesheet carries no token-page specimens", %{css: css} do
    refute css =~ "armature-token-"
  end

  test "every rule sits inside an Armature cascade layer", %{css: css} do
    # Unlayered library rules would compete with a consumer's unlayered
    # overrides on file order instead of always losing to them.
    top_level =
      css
      |> String.replace(~r{/\*.*?\*/}s, "")
      |> top_level_blocks()

    assert Enum.all?(top_level, &String.starts_with?(&1, "@layer")), inspect(top_level)
  end

  describe "optional Barlow stylesheet" do
    setup do
      {:ok, fonts_css: File.read!(Path.expand("../priv/static/armature-fonts.css", __DIR__))}
    end

    test "declares both weights with swap display", %{fonts_css: css} do
      for weight <- [400, 600] do
        assert css =~ "font-weight: #{weight}"
        assert css =~ "fonts/barlow-#{weight}.woff2"
      end

      assert length(Regex.scan(~r/font-display: swap/, css)) == 2
    end

    test "ships real WOFF2 files for both weights" do
      for weight <- [400, 600] do
        assert File.read!(Path.expand("../priv/static/fonts/barlow-#{weight}.woff2", __DIR__))
               |> binary_part(0, 4) == "wOF2"
      end
    end

    test "ships the font licence" do
      assert File.read!(Path.expand("../priv/static/fonts/OFL.txt", __DIR__)) =~
               "SIL OPEN FONT LICENSE Version 1.1"
    end
  end

  # The prelude of each top-level statement or block, found by tracking brace depth.
  defp top_level_blocks(css) do
    {blocks, _depth, _current} =
      css
      |> String.graphemes()
      |> Enum.reduce({[], 0, ""}, fn
        "{", {blocks, 0, current} -> {[String.trim(current) | blocks], 1, ""}
        "{", {blocks, depth, current} -> {blocks, depth + 1, current}
        "}", {blocks, depth, current} -> {blocks, depth - 1, current}
        ";", {blocks, 0, current} -> {[String.trim(current) | blocks], 0, ""}
        char, {blocks, 0, current} -> {blocks, 0, current <> char}
        _char, acc -> acc
      end)

    blocks |> Enum.reverse() |> Enum.reject(&(&1 == ""))
  end

  defp theme_selectors do
    [
      ":root",
      ":root:where(:not([data-armature-theme=\"light\"]))",
      "[data-armature-theme=\"dark\"]",
      "[data-armature-theme=\"light\"]"
    ]
  end

  defp rule!(rules, selector) do
    [{_, values}] = Enum.filter(rules, fn {name, _} -> name == selector end)
    values
  end
end
