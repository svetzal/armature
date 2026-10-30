defmodule Armature.MarkupHelpers do
  @moduledoc false
  import Phoenix.LiveViewTest

  def document(component, assigns \\ %{}) do
    component |> render_component(assigns) |> LazyHTML.from_fragment()
  end

  def present?(doc, selector), do: doc |> LazyHTML.query(selector) |> LazyHTML.to_tree() != []
end
