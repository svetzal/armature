defmodule Armature.Tokens.Values do
  @moduledoc """
  Resolves the token stylesheet contract and checks its WCAG contrast pairs.

  `read/1` reads Armature's defaults followed by consumer stylesheet paths on
  every call. It evaluates `:root`, theme attribute selectors, cascade layers,
  specificity, source order and `!important` in six contexts: the system
  colour preference (light or dark) crossed with the container's theme (none,
  explicit light or explicit dark). See `contexts/0`. Other media conditions are
  excluded: these results describe the ordinary colour schemes, not forced
  colours, reduced motion or viewport-specific target sizes.

  This is a deliberately scoped token evaluator, not a browser CSS engine.
  Use literal opaque hex or RGB colours (or `var()` references with optional
  fallbacks) in these selectors. Unsupported colours and unresolved references
  fail the check rather than silently passing. Imports must be supplied as
  separate paths, in load order. Load the same files in the browser layout.
  """

  alias Armature.Tokens

  # The system colour preference and the container's explicit theme are
  # independent: an explicit theme can be shown while the system prefers the
  # other scheme, and preference media queries still apply inside it. Each
  # context is {system preference, container theme}; :auto sets no attribute.
  @contexts [
    light: {:light, :auto},
    dark: {:dark, :auto},
    explicit_light: {:light, :light},
    explicit_dark: {:dark, :dark},
    explicit_light_on_dark_system: {:dark, :light},
    explicit_dark_on_light_system: {:light, :dark}
  ]

  @labels %{
    light: "Light (Auto)",
    dark: "Dark (Auto)",
    explicit_light: "Light (explicit)",
    explicit_dark: "Dark (explicit)",
    explicit_light_on_dark_system: "Light (explicit, system dark)",
    explicit_dark_on_light_system: "Dark (explicit, system light)"
  }

  @doc "Every evaluated context, in display order, with a readable label."
  def contexts, do: Enum.map(@contexts, fn {name, _} -> {name, Map.fetch!(@labels, name)} end)

  @doc "Reads stylesheet paths after the shipped defaults and returns values and pair results by context."
  def read(paths \\ []) do
    css = Enum.map_join([default_path() | paths], "\n", &File.read!/1)
    rules = parse(css)
    layers = layer_order(css)

    Map.new(@contexts, fn {name, {system, choice}} ->
      root = cascade(rules, layers, system, :auto, :root, %{}) |> resolve_values()

      values =
        if choice == :auto,
          do: root,
          else: cascade(rules, layers, system, choice, :container, root)

      values = resolve_values(values)
      {name, %{values: values, pairs: pairs(values)}}
    end)
  end

  @doc """
  Checks all required pairs in every context (automatic themes, explicit
  themes, and explicit themes under the opposite system preference), raising
  `ArgumentError` with each failing context and pair. Returns `:ok` on success.

      assert :ok = Armature.Tokens.Values.check!(["assets/css/tokens.css"])
  """
  def check!(paths \\ []) do
    failures =
      for {theme, result} <- read(paths), pair <- result.pairs, not pair.pass? do
        "#{theme}: #{pair.foreground} on #{pair.background}: " <>
          "#{pair.ratio || pair.error}:1, requires #{pair.minimum}:1"
      end

    if failures != [], do: raise(ArgumentError, Enum.join(failures, "\n"))
    :ok
  end

  @doc "Extracts token declarations from stylesheet rules in source order, including nested rules."
  def rules(css), do: Enum.map(parse(css), &{&1.selector, &1.declarations})

  defp default_path, do: Application.app_dir(:armature, "priv/static/armature.css")

  defp parse(css) do
    css
    |> String.replace(~r{/\*.*?\*/}s, "")
    |> String.split(~r/([{}])/, include_captures: true, trim: true)
    |> blocks([], [])
  end

  defp blocks([], _context, rules), do: Enum.reverse(rules)

  defp blocks(["}" | rest], [_ | context], rules), do: blocks(rest, context, rules)

  # An empty rule body, such as `:root {}`, declares nothing.
  defp blocks([_prelude, "{", "}" | rest], context, rules), do: blocks(rest, context, rules)

  defp blocks([prelude, "{" | rest], context, rules) do
    selector = prelude |> String.split(";") |> List.last() |> String.trim()

    if String.starts_with?(selector, "@") do
      blocks(rest, [selector | context], rules)
    else
      [body, "}" | rest] = rest
      rule = %{selector: selector, declarations: declarations(body), context: context}
      blocks(rest, context, [rule | rules])
    end
  end

  defp blocks([_ | rest], context, rules), do: blocks(rest, context, rules)

  defp declarations(body) do
    Regex.scan(~r/(--[\w-]+)\s*:\s*([^;{}]+)(?:;|$)/, body)
    |> Enum.map(fn [_, name, value] -> {name, String.trim(value)} end)
  end

  defp layer_order(css) do
    css
    |> String.replace(~r{/\*.*?\*/}s, "")
    |> then(&Regex.scan(~r/@layer\s+([^;{}]+)[;{]/, &1))
    |> Enum.flat_map(fn [_, names] -> String.split(names, ",", trim: true) end)
    |> Enum.map(&String.trim/1)
    |> Enum.uniq()
  end

  defp cascade(rules, layers, system, choice, target, inherited) do
    rules
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {rule, index}, acc ->
      specificity = specificity(rule.selector, system, choice, target)

      if specificity && active?(rule.context, system) do
        Enum.reduce(Enum.with_index(rule.declarations), acc, fn {{name, raw}, declaration_index},
                                                                values ->
          important? = String.ends_with?(raw, "!important")
          value = raw |> String.replace(~r/\s*!important$/, "") |> String.trim()

          rank =
            {important?, layer_rank(rule.context, layers, important?), specificity, index,
             declaration_index}

          Map.update(values, name, {rank, value}, fn previous ->
            if elem(previous, 0) > rank, do: previous, else: {rank, value}
          end)
        end)
      else
        acc
      end
    end)
    |> Map.new(fn {name, {_rank, value}} -> {name, value} end)
    |> then(&Map.merge(inherited, &1))
  end

  defp layer_rank(context, layers, important?) do
    layer = Enum.find(context, &String.starts_with?(&1, "@layer "))

    index =
      if layer,
        do: Enum.find_index(layers, &(&1 == String.replace_prefix(layer, "@layer ", ""))),
        else: length(layers)

    if important?, do: -index, else: index
  end

  defp active?(context, system) do
    Enum.all?(context, fn
      "@layer " <> _ ->
        true

      "@media " <> condition ->
        String.trim(condition) == "(prefers-color-scheme: dark)" and system == :dark

      _ ->
        false
    end)
  end

  defp specificity(selectors, system, choice, target) do
    selectors
    |> String.split(",")
    |> Enum.map(&selector_specificity(String.trim(&1), system, choice, target))
    |> Enum.reject(&is_nil/1)
    |> Enum.max(fn -> nil end)
  end

  defp selector_specificity(":root", _system, _choice, :root), do: 1

  defp selector_specificity(
         ":root:where(:not([data-armature-theme=\"light\"]))",
         :dark,
         _choice,
         :root
       ),
       do: 1

  defp selector_specificity("[data-armature-theme]", _system, _choice, :container), do: 1

  defp selector_specificity(selector, _system, theme, :container) do
    normalized =
      selector
      |> String.replace("'", "\"")
      |> String.replace(~r/\[data-armature-theme=(light|dark)\]/, "[data-armature-theme=\"\\1\"]")

    if normalized == ~s([data-armature-theme="#{theme}"]), do: 1
  end

  defp selector_specificity(_selector, _system, _choice, _target), do: nil

  defp resolve_values(values) do
    Map.new(values, fn {name, value} -> {name, resolve(value, values, [name])} end)
  end

  defp resolve(value, values, seen) do
    Regex.replace(~r/var\(\s*(--[\w-]+)\s*(?:,\s*([^()]+))?\)/, value, fn _, name, fallback ->
      if name in seen do
        "unresolved cycle: #{name}"
      else
        resolve(Map.get(values, name, String.trim(fallback)), values, [name | seen])
      end
    end)
  end

  defp pairs(values) do
    for %{group: :colour} = token <- Tokens.all(), pair <- token.contrast do
      result = contrast(Map.get(values, token.name, ""), Map.get(values, pair.background, ""))

      Map.merge(
        %{foreground: token.name, background: pair.background, minimum: pair.ratio},
        result
      )
      |> Map.put(:pass?, is_number(result.ratio) and result.ratio >= pair.ratio)
    end
  end

  defp contrast(foreground, background) do
    with {:ok, first} <- luminance(foreground), {:ok, second} <- luminance(background) do
      %{ratio: (max(first, second) + 0.05) / (min(first, second) + 0.05), error: nil}
    else
      {:error, value} -> %{ratio: nil, error: "Unsupported or unresolved colour: #{value}"}
    end
  end

  defp luminance(colour) do
    case channels(String.downcase(colour)) do
      {:ok, channels} ->
        value =
          channels
          |> Enum.map(&linearise/1)
          |> Enum.zip([0.2126, 0.7152, 0.0722])
          |> Enum.map(fn {channel, weight} -> channel * weight end)
          |> Enum.sum()

        {:ok, value}

      :error ->
        {:error, colour}
    end
  end

  defp channels("#" <> hex) when byte_size(hex) in [3, 6] do
    hex = if byte_size(hex) == 3, do: String.replace(hex, ~r/./, "\\0\\0"), else: hex

    if Regex.match?(~r/^[0-9a-f]{6}$/, hex) do
      {:ok, for(<<channel::binary-size(2) <- hex>>, do: String.to_integer(channel, 16) / 255)}
    else
      :error
    end
  end

  defp channels("rgb(" <> body) do
    parts = body |> String.trim_trailing(")") |> String.split(~r/[\s,]+/, trim: true)
    channels = Enum.map(parts, &rgb_channel/1)

    if length(channels) == 3 and Enum.all?(channels, &is_number/1),
      do: {:ok, channels},
      else: :error
  end

  defp channels(_), do: :error

  defp rgb_channel(value) do
    case Float.parse(value) do
      {number, ""} when number >= 0 and number <= 255 -> number / 255
      {number, "%"} when number >= 0 and number <= 100 -> number / 100
      _ -> :error
    end
  end

  defp linearise(channel) when channel <= 0.04045, do: channel / 12.92
  defp linearise(channel), do: :math.pow((channel + 0.055) / 1.055, 2.4)
end
