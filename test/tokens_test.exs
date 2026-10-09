defmodule Armature.TokensTest do
  use ExUnit.Case, async: true

  alias Armature.Tokens

  @stylesheet Path.expand("../priv/static/armature.css", __DIR__)
  @guide Path.expand("../guides/tokens.md", __DIR__)
  @named_colours ~w(aliceblue antiquewhite aqua aquamarine azure beige bisque black
    blanchedalmond blue blueviolet brown burlywood cadetblue chartreuse chocolate coral
    cornflowerblue cornsilk crimson cyan darkblue darkcyan darkgoldenrod darkgray darkgrey
    darkgreen darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon
    darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink
    deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro
    ghostwhite gold goldenrod gray grey green greenyellow honeydew hotpink indianred indigo
    ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan
    lightgoldenrodyellow lightgray lightgrey lightgreen lightpink lightsalmon lightseagreen
    lightskyblue lightslategray lightslategrey lightsteelblue lightyellow lime limegreen linen
    magenta maroon mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen
    mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream
    mistyrose moccasin navajowhite navy oldlace olive olivedrab orange orangered orchid
    palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum
    powderblue purple rebeccapurple red rosybrown royalblue saddlebrown salmon sandybrown
    seagreen seashell sienna silver skyblue slateblue slategray slategrey snow springgreen
    steelblue tan teal thistle tomato turquoise violet wheat white whitesmoke yellow
    yellowgreen transparent currentcolor accentcolor accentcolortext activetext buttonborder
    buttonface buttontext canvas canvastext field fieldtext graytext highlight highlighttext
    linktext mark marktext selecteditem selecteditemtext visitedtext activeborder activecaption
    appworkspace background buttonhighlight buttonshadow captiontext inactiveborder
    inactivecaption inactivecaptiontext infobackground infotext menu menutext scrollbar
    threeddarkshadow threedface threedhighlight threedlightshadow threedshadow window
    windowframe windowtext)

  setup do
    css = File.read!(@stylesheet)

    rules =
      Regex.scan(~r/([^{}]+)\{([^{}]*)\}/, Regex.replace(~r{/\*.*?\*/}s, css, ""))
      |> Enum.map(fn [_, selector, body] -> {String.trim(selector), declarations(body)} end)

    {:ok, css: css, rules: rules}
  end

  test "contract names, groups, roles and contrast references are complete" do
    tokens = Tokens.all()
    names = Enum.map(tokens, & &1.name)

    assert names == Enum.uniq(names)

    for token <- tokens do
      assert String.starts_with?(token.name, "--armature-")
      assert token.group in [:colour, :typography, :space, :shape, :motion, :control]
      assert String.ends_with?(token.role, ".")

      if token.group == :colour do
        assert is_list(token.contrast)

        for pair <- token.contrast do
          assert Enum.any?(tokens, &(&1.name == pair.background and &1.group == :colour))
          assert pair.ratio in [3, 4.5]
        end
      end
    end
  end

  test "light, automatic dark and explicit themes define exactly the contract", %{rules: rules} do
    expected = Tokens.all() |> Enum.map(& &1.name) |> Enum.sort()

    for selector <- theme_selectors() do
      values = rule!(rules, selector)
      names = Enum.map(values, &elem(&1, 0))
      assert Enum.sort(names) == expected, "Token mismatch in #{selector}"
    end

    assert rule!(rules, "[data-armature-theme=\"dark\"]") ==
             rule!(rules, ":root:where(:not([data-armature-theme=\"light\"]))")

    assert rule!(rules, ":root") == rule!(rules, "[data-armature-theme=\"light\"]")
  end

  test "all overrides and references belong to the contract", %{css: css} do
    expected = MapSet.new(Tokens.all(), & &1.name)
    names = Regex.scan(~r/--[a-z][\w-]*/, css) |> List.flatten() |> MapSet.new()
    assert names == expected
  end

  test "actual light and dark colour values meet every declared WCAG contrast pair", %{
    rules: rules
  } do
    for selector <- theme_selectors() do
      values = rules |> rule!(selector) |> Map.new()

      for %{group: :colour} = token <- Tokens.all(), pair <- token.contrast do
        foreground = Map.fetch!(values, token.name)
        background = Map.fetch!(values, pair.background)
        ratio = contrast(foreground, background)

        assert ratio >= pair.ratio,
               "#{selector}: #{token.name} on #{pair.background} is #{ratio}:1, needs #{pair.ratio}:1"
      end
    end
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

  test "contrast calculation uses WCAG relative luminance" do
    # Reference extremes and a middle grey exercise both transfer-function branches.
    assert contrast("#000000", "#ffffff") == 21.0
    assert contrast("#ffffff", "#000000") == 21.0
    assert contrast("#777777", "#777777") == 1.0
    assert_in_delta contrast("#777777", "#ffffff"), 4.478, 0.001
  end

  test "base rules use declared variables for dimensions and motion", %{css: css} do
    [_, base] = String.split(css, "@layer armature.base {")
    refute Regex.match?(~r/--[\w-]+\s*:/, base)
    refute Regex.match?(~r/\b\d*\.?\d+(?:px|rem|em|ms|s|%)\b/, base)
    assert base =~ ".armature-sr-only"
    assert base =~ "clip-path: inset(var(--armature-hidden-inset))"
    assert base =~ ":focus-visible"
    assert base =~ "outline: var(--armature-focus-width) solid var(--armature-focus)"
    assert base =~ "@media (prefers-reduced-motion: reduce)"
    assert base =~ "animation-duration: var(--armature-duration-reduced) !important"
    assert base =~ "transition-duration: var(--armature-duration-reduced) !important"
    assert base =~ "@media (forced-colors: active)"
    assert base =~ "[aria-selected=\"true\"]"
    assert base =~ "[aria-invalid=\"true\"]"
    assert base =~ "solid var(--armature-selected-cue)"
    assert base =~ "dashed var(--armature-error-emphasis)"
  end

  test "forced colours keep focus, selection and focused selection visually distinct",
       %{css: css} do
    [_, base] = String.split(css, "@layer armature.base {")
    [_, forced] = String.split(base, "@media (forced-colors: active) {")

    # Focus and the selection cue are both Highlight in forced colours, so
    # each state must differ in outline style or placement, never colour alone.
    shapes =
      for selector <- [~s([aria-selected="true"]), ~s([aria-selected="true"]:focus-visible)] do
        outline_shape(forced, selector)
      end

    focus = outline_shape(base, ":focus-visible")
    [selected, focused_selected] = shapes

    assert Enum.uniq([focus, selected, focused_selected]) |> length() == 3
    assert focused_selected.offset == :outside
    assert focused_selected.style != selected.style or focused_selected.offset != selected.offset
  end

  test "theme and accessibility media rules apply in cascade order", %{css: css, rules: rules} do
    assert css =~ "@layer armature.tokens, armature.base;"
    assert css =~ "@media (prefers-color-scheme: dark)"
    assert css =~ "@media (pointer: coarse), (max-width: 40rem)"

    selectors = Enum.map(rules, &elem(&1, 0))
    positions = Enum.map(theme_selectors(), &Enum.find_index(selectors, fn s -> s == &1 end))
    assert Enum.sort(positions) == positions

    overrides =
      Enum.filter(rules, fn {selector, _} -> selector == ":root, [data-armature-theme]" end)

    [{_, targets}, {_, motion}, {_, forced}] = overrides

    for name <- ["--armature-control-height", "--armature-target-size"] do
      {pixels, "px"} = targets |> Map.new() |> Map.fetch!(name) |> Integer.parse()
      assert pixels >= 44
    end

    assert Map.new(motion) == %{
             "--armature-duration-fast" => "var(--armature-duration-reduced)",
             "--armature-duration-base" => "var(--armature-duration-reduced)"
           }

    colour_names = Tokens.all() |> Enum.filter(&(&1.group == :colour)) |> Enum.map(& &1.name)
    assert Enum.sort(Map.keys(Map.new(forced))) == Enum.sort(colour_names)
    assert Map.new(forced)["--armature-focus"] == "Highlight"
    assert Map.new(forced)["--armature-selected-cue"] == "Highlight"
    assert Map.new(forced)["--armature-error-emphasis"] == "CanvasText"
  end

  test "guide table is generated from the contract" do
    guide = File.read!(@guide)
    [_, generated] = String.split(guide, "<!-- tokens:start -->\n")
    [table, _] = String.split(generated, "<!-- tokens:end -->")
    assert table == Tokens.markdown_table()
  end

  defp theme_selectors do
    [
      ":root",
      ":root:where(:not([data-armature-theme=\"light\"]))",
      "[data-armature-theme=\"dark\"]",
      "[data-armature-theme=\"light\"]"
    ]
  end

  defp declarations(body) do
    Regex.scan(~r/(--[\w-]+)\s*:\s*([^;{}]+);/, body)
    |> Enum.map(fn [_, name, value] -> {name, String.trim(value)} end)
  end

  # The outline style and whether it sits inside or outside the element, for
  # the first rule in `css` whose selector is exactly `selector`.
  defp outline_shape(css, selector) do
    pattern = ~r/(?:^|[}\s])#{Regex.escape(selector)}\s*\{([^}]*)\}/
    [_, body] = Regex.run(pattern, css)
    [_, style] = Regex.run(~r/outline:\s*\S+(?:\s*\*\s*\d+\))?\s+(\w+)/, body)
    [_, offset] = Regex.run(~r/outline-offset:\s*([^;]+);/, body)
    %{style: style, offset: if(offset =~ "* -1", do: :inside, else: :outside)}
  end

  defp rule!(rules, selector) do
    [{_, values}] = Enum.filter(rules, fn {name, _} -> name == selector end)
    values
  end

  defp colour_literal?(text) do
    # Ignore custom-property names, class names, strings and property names.
    text = Regex.replace(~r/(?:--[\w-]+|\.[a-z][\w-]*|"[^"]*")/i, text, "")
    text = Regex.replace(~r/\b[a-z][\w-]*\s*:/i, text, "")
    named = Enum.join(@named_colours, "|")

    Regex.match?(~r/#[0-9a-f]{3,8}\b|\b(?:rgba?|hsla?|oklch|oklab|lab|lch|color)\s*\(/i, text) or
      Regex.match?(Regex.compile!("\\b(?:#{named})\\b", "i"), text)
  end

  defp contrast(foreground, background) do
    first = luminance(foreground)
    second = luminance(background)
    (max(first, second) + 0.05) / (min(first, second) + 0.05)
  end

  defp luminance("#" <> hex) when byte_size(hex) == 6 do
    <<red::binary-size(2), green::binary-size(2), blue::binary-size(2)>> = hex

    [red, green, blue]
    |> Enum.map(fn channel ->
      channel |> String.to_integer(16) |> Kernel./(255) |> linearise()
    end)
    |> Enum.zip([0.2126, 0.7152, 0.0722])
    |> Enum.map(fn {channel, weight} -> channel * weight end)
    |> Enum.sum()
  end

  defp linearise(channel) when channel <= 0.04045, do: channel / 12.92
  defp linearise(channel), do: :math.pow((channel + 0.055) / 1.055, 2.4)
end
