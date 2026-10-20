defmodule Armature.Catalogue.Preview do
  @moduledoc false

  @sectioning ~w(article aside main nav section)
  @void ~w(area base br col embed hr img input link meta param source track wbr)

  # True when the example would add a page-level landmark to the catalogue's
  # own document: a main element, an explicit main, banner or contentinfo
  # role, or a header or footer that no sectioning element contains. Such
  # examples render in their own document. A header inside an aside is not a
  # page landmark, so interactive compositions stay inline and keep working.
  @spec isolated?(String.t()) :: boolean()
  def isolated?(html) do
    if Regex.match?(~r/<main\b|role=["'](?:main|banner|contentinfo)["']/i, html) do
      true
    else
      ~r/<(\/?)([a-zA-Z][\w-]*)\b[^>]*?(\/?)>/
      |> Regex.scan(html)
      |> Enum.reduce_while([], fn [_, closing, name, self_closing], stack ->
        name = String.downcase(name)

        cond do
          closing == "/" ->
            {:cont, drop_to(stack, name)}

          name in ~w(header footer) and not Enum.any?(stack, &(&1 in @sectioning)) ->
            {:halt, :landmark}

          self_closing == "/" or name in @void ->
            {:cont, stack}

          true ->
            {:cont, [name | stack]}
        end
      end)
      |> Kernel.==(:landmark)
    end
  end

  @spec document(String.t(), String.t(), String.t()) :: String.t()
  def document(html, theme, stylesheet) do
    theme = if theme == "auto", do: "", else: ~s(data-armature-theme="#{theme}")

    ~s(<!doctype html><html lang="en" #{theme}><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><style>) <>
      stylesheet <>
      "body { margin: var(--armature-space-zero); }</style></head><body>" <>
      html <> "</body></html>"
  end

  defp drop_to(stack, name) do
    case Enum.split_while(stack, &(&1 != name)) do
      {_inner, [^name | rest]} -> rest
      {_inner, []} -> stack
    end
  end
end
