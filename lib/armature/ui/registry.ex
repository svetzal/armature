defmodule Armature.UI.Registry do
  @moduledoc "The baseline components and their composition contracts."
  @behaviour Armature.Registry
  alias Armature.Components.Atoms
  alias Armature.Components.Layouts
  alias Armature.Components.Molecules
  alias Armature.Components.Organisms
  alias Armature.Components.Templates
  alias Armature.Registry.Node

  @impl true
  def modules, do: [Atoms, Layouts, Molecules, Organisms, Templates]

  @impl true
  def nodes do
    [
      %Node{
        id: :eyebrow,
        level: :atom,
        module: Atoms,
        function: :eyebrow,
        purpose: "A contextual uppercase label.",
        uses: []
      },
      %Node{
        id: :page_heading,
        level: :molecule,
        module: Molecules,
        function: :page_heading,
        purpose: "A page heading with context and actions.",
        uses: [:eyebrow, :cluster]
      },
      %Node{
        id: :theme_switch,
        level: :molecule,
        module: Molecules,
        function: :theme_switch,
        purpose: "A segmented system, light or dark choice of native radios.",
        uses: [:icon]
      },
      %Node{
        id: :side_nav,
        level: :organism,
        module: Organisms,
        function: :side_nav,
        purpose: "Named section navigation with a brand and footnote.",
        uses: [:eyebrow, :link]
      },
      %Node{
        id: :top_bar,
        level: :organism,
        module: Organisms,
        function: :top_bar,
        purpose: "A context band with actions.",
        uses: [:cluster]
      },
      %Node{
        id: :grouped_nav,
        level: :organism,
        module: Organisms,
        function: :grouped_nav,
        purpose: "Grouped navigation with a labelled narrow-screen picker.",
        uses: [:eyebrow, :link, :select]
      },
      %Node{
        id: :panel,
        level: :organism,
        module: Organisms,
        function: :panel,
        purpose: "A named content panel with heading and actions.",
        uses: [:cluster]
      },
      %Node{
        id: :app_shell,
        level: :template,
        module: Templates,
        function: :app_shell,
        purpose: "An application shell with skip navigation and a page heading.",
        uses: [:link, :side_nav, :top_bar, :page_heading]
      },
      %Node{
        id: :button,
        level: :atom,
        module: Atoms,
        function: :button,
        purpose: "A named native action.",
        uses: []
      },
      %Node{
        id: :link,
        level: :atom,
        module: Atoms,
        function: :link,
        purpose: "A named navigation link.",
        uses: []
      },
      %Node{
        id: :icon,
        level: :atom,
        module: Atoms,
        function: :icon,
        purpose: "A decorative vendored glyph or consumer SVG.",
        uses: []
      },
      %Node{
        id: :input,
        level: :atom,
        module: Atoms,
        function: :input,
        purpose: "A native single-line control.",
        uses: []
      },
      %Node{
        id: :select,
        level: :atom,
        module: Atoms,
        function: :select,
        purpose: "A native option control.",
        uses: []
      },
      %Node{
        id: :textarea,
        level: :atom,
        module: Atoms,
        function: :textarea,
        purpose: "A native multiline control.",
        uses: []
      },
      %Node{
        id: :status,
        level: :atom,
        module: Atoms,
        function: :status,
        purpose: "A status expressed in words.",
        uses: []
      },
      %Node{
        id: :stack,
        level: :layout,
        module: Layouts,
        function: :stack,
        purpose: "Vertical rhythm.",
        uses: []
      },
      %Node{
        id: :cluster,
        level: :layout,
        module: Layouts,
        function: :cluster,
        purpose: "A wrapping inline group.",
        uses: []
      },
      %Node{
        id: :grid,
        level: :layout,
        module: Layouts,
        function: :grid,
        purpose: "Responsive minimum-width columns.",
        uses: []
      },
      %Node{
        id: :split,
        level: :layout,
        module: Layouts,
        function: :split,
        purpose: "Two regions that stack.",
        uses: []
      },
      %Node{
        id: :field,
        level: :molecule,
        module: Molecules,
        function: :field,
        purpose: "A labelled control with hint and validation.",
        uses: [:input, :select, :textarea]
      },
      %Node{
        id: :facts,
        level: :molecule,
        module: Molecules,
        function: :facts,
        purpose: "Labelled record facts in a description list.",
        uses: []
      },
      %Node{
        id: :notice,
        level: :molecule,
        module: Molecules,
        function: :notice,
        purpose: "Static guidance or reported results with actions.",
        uses: []
      },
      %Node{
        id: :table_toolbar,
        level: :molecule,
        module: Molecules,
        function: :table_toolbar,
        purpose: "A labelled search and announced result count.",
        uses: [:input, :icon, :button]
      },
      %Node{
        id: :icon_button,
        level: :molecule,
        module: Molecules,
        function: :icon_button,
        purpose: "A named square action or toggle showing only an icon.",
        uses: [:button, :icon]
      },
      %Node{
        id: :toolbar,
        level: :molecule,
        module: Molecules,
        function: :toolbar,
        purpose: "A named group of controls with one tab stop and arrow-key movement.",
        uses: []
      },
      %Node{
        id: :pagination,
        level: :molecule,
        module: Molecules,
        function: :pagination,
        purpose: "Named paging controls and an announced range.",
        uses: [:button, :select]
      },
      %Node{
        id: :record_header,
        level: :molecule,
        module: Molecules,
        function: :record_header,
        purpose: "A record heading with context and actions.",
        uses: [:status]
      },
      %Node{
        id: :data_table,
        level: :organism,
        module: Organisms,
        function: :data_table,
        purpose: "A sortable native table with named record selection.",
        uses: []
      },
      %Node{
        id: :inspector,
        level: :organism,
        module: Organisms,
        function: :inspector,
        purpose: "A named complementary details landmark.",
        uses: []
      },
      %Node{
        id: :table_inspector,
        level: :template,
        module: Templates,
        function: :table_inspector,
        purpose: "A complete table and supporting details workflow.",
        uses: [:link, :split, :table_toolbar, :data_table, :pagination, :inspector]
      }
    ]
  end
end
