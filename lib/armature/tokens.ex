defmodule Armature.Tokens do
  @moduledoc """
  The CSS custom-property contract shared by Armature and its consumers.

  Each token has a name, group and plain-language role. Colour tokens also
  list required contrast pairs as background token names and minimum WCAG
  ratios. Decorative surfaces have no independent contrast requirement;
  their text and cues declare the requirements against them.

  Consumers may override values but must preserve these contrast pairs.
  Feedback needs a text label or symbol, and selection needs a non-colour
  cue. A focus ring's offset places it against the surrounding surface.
  """

  @content_surfaces ~w(
    --armature-paper --armature-canvas --armature-stripe --armature-hover
    --armature-selected --armature-image-backdrop --armature-success-bg
    --armature-warning-bg --armature-error-bg
  )
  @text_contrast Enum.map(@content_surfaces, &%{background: &1, ratio: 4.5})
  @cue_contrast Enum.map(@content_surfaces, &%{background: &1, ratio: 3})

  @tokens [
    %{
      name: "--armature-ink",
      group: :colour,
      role: "Primary text on content surfaces.",
      contrast: @text_contrast
    },
    %{
      name: "--armature-muted",
      group: :colour,
      role: "Secondary text that remains readable on content surfaces.",
      contrast: @text_contrast
    },
    %{
      name: "--armature-accent",
      group: :colour,
      role: "Emphasised text and links on content surfaces.",
      contrast: @text_contrast
    },
    %{
      name: "--armature-on-accent",
      group: :colour,
      role: "Text on an accent-filled control.",
      contrast: [%{background: "--armature-accent", ratio: 4.5}]
    },
    %{name: "--armature-paper", group: :colour, role: "Primary content surface.", contrast: []},
    %{
      name: "--armature-canvas",
      group: :colour,
      role: "Page surface behind content.",
      contrast: []
    },
    %{
      name: "--armature-line",
      group: :colour,
      role: "Decorative separators that do not convey state.",
      contrast: []
    },
    %{
      name: "--armature-control-border",
      group: :colour,
      role: "Boundary of an interactive control.",
      contrast: @cue_contrast
    },
    %{
      name: "--armature-input-border",
      group: :colour,
      role: "Boundary of an editable input.",
      contrast: @cue_contrast
    },
    %{
      name: "--armature-focus",
      group: :colour,
      role: "Visible keyboard focus ring.",
      contrast: @cue_contrast
    },
    %{
      name: "--armature-success-bg",
      group: :colour,
      role: "Surface for success feedback accompanied by a text label.",
      contrast: []
    },
    %{
      name: "--armature-warning-bg",
      group: :colour,
      role: "Surface for warning feedback accompanied by a text label.",
      contrast: []
    },
    %{
      name: "--armature-error-bg",
      group: :colour,
      role: "Surface for error feedback accompanied by a text label.",
      contrast: []
    },
    %{
      name: "--armature-success-emphasis",
      group: :colour,
      role: "Text and symbol emphasising success feedback.",
      contrast: [%{background: "--armature-success-bg", ratio: 4.5}]
    },
    %{
      name: "--armature-warning-emphasis",
      group: :colour,
      role: "Text and symbol emphasising warning feedback.",
      contrast: [%{background: "--armature-warning-bg", ratio: 4.5}]
    },
    %{
      name: "--armature-error-emphasis",
      group: :colour,
      role: "Text and symbol emphasising error feedback.",
      contrast: [
        %{background: "--armature-error-bg", ratio: 4.5},
        %{background: "--armature-paper", ratio: 4.5},
        %{background: "--armature-canvas", ratio: 4.5}
      ]
    },
    %{name: "--armature-stripe", group: :colour, role: "Alternating row surface.", contrast: []},
    %{name: "--armature-hover", group: :colour, role: "Surface of a hovered item.", contrast: []},
    %{
      name: "--armature-selected",
      group: :colour,
      role: "Surface of a selected item.",
      contrast: []
    },
    %{
      name: "--armature-selected-cue",
      group: :colour,
      role: "Non-text outline or marker identifying a selected item.",
      contrast: @cue_contrast
    },
    %{
      name: "--armature-image-backdrop",
      group: :colour,
      role: "Surface behind an image or its placeholder.",
      contrast: []
    },
    %{
      name: "--armature-font-sans",
      group: :typography,
      role: "Font family for prose and controls."
    },
    %{
      name: "--armature-font-mono",
      group: :typography,
      role: "Font family for code and aligned numeric content."
    },
    %{name: "--armature-text-small", group: :typography, role: "Size of supporting text."},
    %{name: "--armature-text-base", group: :typography, role: "Size of primary text."},
    %{name: "--armature-text-large", group: :typography, role: "Size of prominent text."},
    %{name: "--armature-text-heading", group: :typography, role: "Size of section headings."},
    %{
      name: "--armature-line-height",
      group: :typography,
      role: "Line height for readable prose."
    },
    %{name: "--armature-weight-normal", group: :typography, role: "Weight of ordinary text."},
    %{name: "--armature-weight-emphasis", group: :typography, role: "Weight of emphasised text."},
    %{
      name: "--armature-space-zero",
      group: :space,
      role: "Zero spacing for accessibility utilities."
    },
    %{name: "--armature-space-1", group: :space, role: "Smallest gap between related content."},
    %{name: "--armature-space-2", group: :space, role: "Compact gap or inset."},
    %{name: "--armature-space-3", group: :space, role: "Gap between closely related controls."},
    %{name: "--armature-space-4", group: :space, role: "Default content gap or inset."},
    %{name: "--armature-space-6", group: :space, role: "Gap between content groups."},
    %{name: "--armature-space-8", group: :space, role: "Gap between sections."},
    %{name: "--armature-radius-small", group: :shape, role: "Corner radius for small elements."},
    %{
      name: "--armature-radius-base",
      group: :shape,
      role: "Corner radius for controls and surfaces."
    },
    %{name: "--armature-border-width", group: :shape, role: "Width of a visible boundary."},
    %{
      name: "--armature-hidden-size",
      group: :shape,
      role: "Clipped box size for screen-reader-only content."
    },
    %{
      name: "--armature-hidden-inset",
      group: :shape,
      role: "Clipping inset for screen-reader-only content."
    },
    %{
      name: "--armature-duration-fast",
      group: :motion,
      role: "Duration of a short feedback transition."
    },
    %{name: "--armature-duration-base", group: :motion, role: "Duration of a normal transition."},
    %{
      name: "--armature-duration-reduced",
      group: :motion,
      role: "Duration used when reduced motion is requested."
    },
    %{
      name: "--armature-iterations-reduced",
      group: :motion,
      role: "Animation iteration limit when reduced motion is requested."
    },
    %{name: "--armature-easing", group: :motion, role: "Timing function for transitions."},
    %{
      name: "--armature-control-height",
      group: :control,
      role: "Minimum height of a standard control."
    },
    %{
      name: "--armature-target-size",
      group: :control,
      role: "Minimum interactive target size in either dimension."
    },
    %{name: "--armature-focus-width", group: :control, role: "Width of the visible focus ring."},
    %{
      name: "--armature-focus-offset",
      group: :control,
      role: "Gap placing the focus ring on the surrounding surface."
    }
  ]

  @doc "Returns the ordered token contract, including required colour contrast pairs."
  @spec all() :: [map()]
  def all, do: @tokens

  @doc "Renders the contract as a Markdown table for consumer documentation."
  @spec markdown_table() :: String.t()
  def markdown_table do
    header = "| Token | Group | Role | Required contrast |\n| --- | --- | --- | --- |"

    rows =
      Enum.map(@tokens, fn token ->
        pairs =
          token
          |> Map.get(:contrast, [])
          |> Enum.map_join(", ", fn pair ->
            "`#{pair.background}` #{pair.ratio}:1"
          end)

        "| `#{token.name}` | #{token.group} | #{token.role} | #{pairs} |"
      end)

    Enum.join([header | rows], "\n") <> "\n"
  end
end
