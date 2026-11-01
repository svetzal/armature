defmodule Armature.Icons do
  @moduledoc """
  The base icon set: general-purpose glyphs vendored from Lucide.

  Each glyph is the inner markup of a 24 by 24 stroked SVG, drawn in
  `currentColor`. `Armature.Components.Atoms.icon/1` renders a glyph by name; use
  `names/0` to list them. The glyphs come unchanged from the `lucide-static`
  npm package, version 1.58.0, under the ISC licence. The licence text
  ships in `priv/icons/LICENSE.txt`.

  The set stays small and general: a glyph belongs here only when an
  unrelated Phoenix application would want it. Supply any other glyph as your
  own inline SVG in its slot.
  """

  @lucide_version "1.58.0"

  # Lucide's names, so a glyph can be traced back to its source file.
  @glyphs %{
    "arrow-down" => ~S|<path d="M12 5v14" /><path d="m19 12-7 7-7-7" />|,
    "arrow-up" => ~S|<path d="m5 12 7-7 7 7" /><path d="M12 19V5" />|,
    "arrow-up-down" =>
      ~S|<path d="m21 16-4 4-4-4" /><path d="M17 20V4" /><path d="m3 8 4-4 4 4" /><path d="M7 4v16" />|,
    "check" => ~S|<path d="M20 6 9 17l-5-5" />|,
    "chevron-down" => ~S|<path d="m6 9 6 6 6-6" />|,
    "chevron-left" => ~S|<path d="m15 18-6-6 6-6" />|,
    "chevron-right" => ~S|<path d="m9 18 6-6-6-6" />|,
    "chevron-up" => ~S|<path d="m18 15-6-6-6 6" />|,
    "circle-alert" =>
      ~S|<circle cx="12" cy="12" r="10" /><line x1="12" x2="12" y1="8" y2="12" /><line x1="12" x2="12.01" y1="16" y2="16" />|,
    "circle-check" => ~S|<circle cx="12" cy="12" r="10" /><path d="m16 9-5.5 5.5L8 12" />|,
    "copy" =>
      ~S|<rect width="14" height="14" x="8" y="8" rx="2" ry="2" /><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />|,
    "download" =>
      ~S|<path d="M12 15V3" /><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><path d="m7 10 5 5 5-5" />|,
    "ellipsis" =>
      ~S|<circle cx="12" cy="12" r="1" /><circle cx="19" cy="12" r="1" /><circle cx="5" cy="12" r="1" />|,
    "ellipsis-vertical" =>
      ~S|<circle cx="12" cy="12" r="1" /><circle cx="12" cy="5" r="1" /><circle cx="12" cy="19" r="1" />|,
    "external-link" =>
      ~S|<path d="M15 3h6v6" /><path d="M10 14 21 3" /><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />|,
    "eye" =>
      ~S|<path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0" /><circle cx="12" cy="12" r="3" />|,
    "eye-off" =>
      ~S|<path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49" /><path d="M14.084 14.158a3 3 0 0 1-4.242-4.242" /><path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143" /><path d="m2 2 20 20" />|,
    "funnel" =>
      ~S|<path d="M10 20a1 1 0 0 0 .553.895l2 1A1 1 0 0 0 14 21v-7a2 2 0 0 1 .517-1.341L21.74 4.67A1 1 0 0 0 21 3H3a1 1 0 0 0-.742 1.67l7.225 7.989A2 2 0 0 1 10 14z" />|,
    "info" => ~S|<circle cx="12" cy="12" r="10" /><path d="M12 16v-4" /><path d="M12 8h.01" />|,
    "menu" => ~S|<path d="M4 5h16" /><path d="M4 12h16" /><path d="M4 19h16" />|,
    "minus" => ~S|<path d="M5 12h14" />|,
    "monitor" =>
      ~S|<rect width="20" height="14" x="2" y="3" rx="2" /><line x1="8" x2="16" y1="21" y2="21" /><line x1="12" x2="12" y1="17" y2="21" />|,
    "moon" =>
      ~S|<path d="M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401" />|,
    "pencil" =>
      ~S|<path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z" /><path d="m15 5 4 4" />|,
    "plus" => ~S|<path d="M5 12h14" /><path d="M12 5v14" />|,
    "refresh-cw" =>
      ~S|<path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8" /><path d="M21 3v5h-5" /><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16" /><path d="M8 16H3v5" />|,
    "search" => ~S|<path d="m21 21-4.34-4.34" /><circle cx="11" cy="11" r="8" />|,
    "settings" =>
      ~S|<path d="M9.671 4.136a2.34 2.34 0 0 1 4.659 0 2.34 2.34 0 0 0 3.319 1.915 2.34 2.34 0 0 1 2.33 4.033 2.34 2.34 0 0 0 0 3.831 2.34 2.34 0 0 1-2.33 4.033 2.34 2.34 0 0 0-3.319 1.915 2.34 2.34 0 0 1-4.659 0 2.34 2.34 0 0 0-3.32-1.915 2.34 2.34 0 0 1-2.33-4.033 2.34 2.34 0 0 0 0-3.831A2.34 2.34 0 0 1 6.35 6.051a2.34 2.34 0 0 0 3.319-1.915" /><circle cx="12" cy="12" r="3" />|,
    "sun" =>
      ~S|<circle cx="12" cy="12" r="4" /><path d="M12 2v2" /><path d="M12 20v2" /><path d="m4.93 4.93 1.41 1.41" /><path d="m17.66 17.66 1.41 1.41" /><path d="M2 12h2" /><path d="M20 12h2" /><path d="m6.34 17.66-1.41 1.41" /><path d="m19.07 4.93-1.41 1.41" />|,
    "trash-2" =>
      ~S|<path d="M10 11v6" /><path d="M14 11v6" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6" /><path d="M3 6h18" /><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />|,
    "triangle-alert" =>
      ~S|<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" /><path d="M12 9v4" /><path d="M12 17h.01" />|,
    "upload" =>
      ~S|<path d="M12 3v12" /><path d="m17 8-5-5-5 5" /><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />|,
    "x" => ~S|<path d="M18 6 6 18" /><path d="m6 6 12 12" />|
  }

  @names @glyphs |> Map.keys() |> Enum.sort()

  @doc "The version of `lucide-static` the glyphs were taken from."
  @spec lucide_version() :: String.t()
  def lucide_version, do: @lucide_version

  @doc "The names of every vendored glyph, sorted."
  @spec names() :: [String.t()]
  def names, do: @names

  @doc """
  The inner SVG markup of the glyph called `name`.

  Raises `ArgumentError` naming the known glyphs when `name` is not one of them.
  """
  @spec glyph!(String.t()) :: String.t()
  def glyph!(name) do
    case Map.fetch(@glyphs, name) do
      {:ok, markup} ->
        markup

      :error ->
        raise ArgumentError,
              "unknown icon #{inspect(name)}; known icons are: #{Enum.join(@names, ", ")}"
    end
  end
end
