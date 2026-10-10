defmodule Armature.UI.Registry do
  @moduledoc "The baseline components and their composition contracts."
  @behaviour Armature.Registry
  alias Armature.Registry.Node

  @impl true
  def modules, do: [Armature.Components]

  @impl true
  def nodes do
    [
      %Node{
        id: :button,
        level: :atom,
        module: Armature.Components,
        function: :button,
        purpose: "A named native action.",
        uses: []
      },
      %Node{
        id: :link,
        level: :atom,
        module: Armature.Components,
        function: :link,
        purpose: "A named navigation link.",
        uses: []
      },
      %Node{
        id: :icon,
        level: :atom,
        module: Armature.Components,
        function: :icon,
        purpose: "Decorative consumer SVG.",
        uses: []
      },
      %Node{
        id: :input,
        level: :atom,
        module: Armature.Components,
        function: :input,
        purpose: "A native single-line control.",
        uses: []
      },
      %Node{
        id: :select,
        level: :atom,
        module: Armature.Components,
        function: :select,
        purpose: "A native option control.",
        uses: []
      },
      %Node{
        id: :textarea,
        level: :atom,
        module: Armature.Components,
        function: :textarea,
        purpose: "A native multiline control.",
        uses: []
      },
      %Node{
        id: :status,
        level: :atom,
        module: Armature.Components,
        function: :status,
        purpose: "A status expressed in words.",
        uses: []
      },
      %Node{
        id: :stack,
        level: :layout,
        module: Armature.Components,
        function: :stack,
        purpose: "Vertical rhythm.",
        uses: []
      },
      %Node{
        id: :cluster,
        level: :layout,
        module: Armature.Components,
        function: :cluster,
        purpose: "A wrapping inline group.",
        uses: []
      },
      %Node{
        id: :grid,
        level: :layout,
        module: Armature.Components,
        function: :grid,
        purpose: "Responsive minimum-width columns.",
        uses: []
      },
      %Node{
        id: :split,
        level: :layout,
        module: Armature.Components,
        function: :split,
        purpose: "Two regions that stack.",
        uses: []
      },
      %Node{
        id: :field,
        level: :molecule,
        module: Armature.Components,
        function: :field,
        purpose: "A labelled control with hint and validation.",
        uses: [:input, :select, :textarea]
      },
      %Node{
        id: :notice,
        level: :molecule,
        module: Armature.Components,
        function: :notice,
        purpose: "Static guidance or reported results with actions.",
        uses: []
      },
      %Node{
        id: :table_toolbar,
        level: :molecule,
        module: Armature.Components,
        function: :table_toolbar,
        purpose: "A labelled search and announced result count.",
        uses: [:input]
      },
      %Node{
        id: :pagination,
        level: :molecule,
        module: Armature.Components,
        function: :pagination,
        purpose: "Named paging controls and an announced range.",
        uses: [:button, :select]
      },
      %Node{
        id: :record_header,
        level: :molecule,
        module: Armature.Components,
        function: :record_header,
        purpose: "A record heading with context and actions.",
        uses: [:status]
      },
      %Node{
        id: :data_table,
        level: :organism,
        module: Armature.Components,
        function: :data_table,
        purpose: "A sortable native table with named record selection.",
        uses: []
      },
      %Node{
        id: :inspector,
        level: :organism,
        module: Armature.Components,
        function: :inspector,
        purpose: "A named complementary details landmark.",
        uses: []
      },
      %Node{
        id: :table_inspector,
        level: :template,
        module: Armature.Components,
        function: :table_inspector,
        purpose: "A complete table and supporting details workflow.",
        uses: [:link, :split, :table_toolbar, :data_table, :pagination, :inspector]
      }
    ]
  end
end
