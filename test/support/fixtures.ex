defmodule Armature.Fixtures.Elements do
  @moduledoc false
  use Phoenix.Component

  attr(:label, :string, default: "Example")
  def text(assigns), do: ~H"<span>{@label}</span>"

  attr(:label, :string, default: "Example")
  def mark(assigns), do: ~H"<span>{@label}</span>"

  def ordinary(value), do: value
end

defmodule Armature.Fixtures.Compositions do
  @moduledoc false
  use Phoenix.Component
  import Armature.Fixtures.Elements, only: [mark: 1]
  alias Armature.Fixtures.Elements, as: Primitive

  attr(:label, :string, default: "Example")
  def row(assigns), do: ~H"<div><Primitive.text label={@label} /></div>"

  attr(:label, :string, default: "Example")

  def group(assigns) do
    ~H"""
    <div><.row label={@label} /><.helper label={@label} /></div>
    <%!-- <Primitive.ignored /> --%>
    """
  end

  attr(:label, :string, default: "Example")
  def section(assigns), do: ~H"<section><.group label={@label} /></section>"

  attr(:label, :string, default: "Example")
  def region(assigns), do: ~H"<section><.section label={@label} /></section>"

  attr(:label, :string, default: "Example")

  def page(assigns),
    do: ~H"""
    <main><.region label={@label} /><.link href="/">Example</.link></main>
    """

  attr(:label, :string, default: "Example")
  defp helper(assigns), do: ~H"<.mark label={@label} />"
end

defmodule Armature.Fixtures.Registry do
  @moduledoc false
  @behaviour Armature.Registry
  alias Armature.Fixtures.Compositions
  alias Armature.Fixtures.Elements
  alias Armature.Registry.Node

  @impl true
  def modules, do: [Elements, Compositions]

  @impl true
  def nodes do
    [
      node(:text, :atom, Elements, []),
      node(:mark, :atom, Elements, []),
      node(:row, :layout, Compositions, [:text]),
      node(:group, :molecule, Compositions, [:row, :mark]),
      node(:section, :organism, Compositions, [:group]),
      node(:region, :organism, Compositions, [:section]),
      node(:page, :template, Compositions, [:region])
    ]
  end

  defp node(id, level, module, uses) do
    %Node{
      id: id,
      function: id,
      level: level,
      module: module,
      purpose: "Demonstrates #{id} composition.",
      uses: uses
    }
  end
end
