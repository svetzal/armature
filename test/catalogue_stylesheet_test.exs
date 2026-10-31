defmodule Armature.CatalogueStylesheetTest do
  use ExUnit.Case, async: true

  import Armature.CssGuards, only: [colour_literal?: 1]

  @stylesheet Path.expand("../priv/catalogue/catalogue.css", __DIR__)

  setup do
    {:ok, css: File.read!(@stylesheet)}
  end

  test "every custom property it references belongs to the token contract", %{css: css} do
    contract = MapSet.new(Armature.Tokens.all(), & &1.name)
    names = Regex.scan(~r/--[a-z][\w-]*/, css) |> List.flatten() |> MapSet.new()
    assert MapSet.subset?(names, contract), inspect(MapSet.difference(names, contract))
  end

  test "defines no custom properties", %{css: css} do
    refute Regex.match?(~r/--[\w-]+\s*:/, css)
  end

  test "contains no colour literals", %{css: css} do
    refute colour_literal?(Regex.replace(~r{/\*.*?\*/}s, css, ""))
  end

  test "uses declared variables instead of literal dimensions or durations", %{css: css} do
    # Breakpoints cannot consume CSS custom properties; declarations still must.
    declarations = Regex.replace(~r/@(?:media|container)[^{]+\{/, css, "")
    refute Regex.match?(~r/\b\d*\.?\d+(?:px|rem|em|ms|s)\b/, declarations)
  end
end
