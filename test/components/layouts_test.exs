defmodule Armature.Components.LayoutsTest do
  use Armature.ComponentsCase, async: true
  alias Armature.Components.Layouts

  describe "layouts" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Layouts.stack id="stack">
            <p>First</p><p>Second</p>
          </Layouts.stack>
          <Layouts.cluster id="cluster">
            <p>First</p><p>Second</p>
          </Layouts.cluster>
          <Layouts.grid id="grid">
            <p>First</p><p>Second</p>
          </Layouts.grid>
          <Layouts.split id="split">
            <p>First</p><:secondary>
              <p>Second</p>
            </:secondary>
          </Layouts.split>
          """
        end)

      %{doc: doc}
    end

    test "every layout preserves content order", %{doc: doc} do
      for name <- ~w(stack cluster grid split) do
        assert present?(doc, "div##{name}.armature-#{name}")

        assert doc
               |> LazyHTML.query("##{name} p")
               |> LazyHTML.to_tree()
               |> Enum.map(fn {_, _, [content]} -> content end) == ["First", "Second"]
      end
    end

    test "layouts add no semantic roles", %{doc: doc} do
      refute present?(doc, "[role], aside, section, main")
    end
  end
end
