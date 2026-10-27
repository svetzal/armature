defmodule Armature.Catalogue.PageTest do
  use ExUnit.Case, async: true

  alias Armature.Catalogue.Page
  alias Armature.Registry.Node

  @button %Node{id: :button, level: :atom, module: M, function: :button, purpose: "Acts."}
  @field %Node{
    id: :field,
    level: :molecule,
    module: M,
    function: :field,
    purpose: "Labels.",
    uses: [:button]
  }
  @table %Node{id: :table, level: :organism, module: M, function: :table, purpose: "Lists."}
  @panel %Node{id: :panel, level: :organism, module: M, function: :panel, purpose: "Groups."}
  @nodes [@button, @field, @table, @panel]

  defp assert_index(page) do
    assert page.node == nil
    assert page.level == nil
    refute page.tokens?
    assert page.heading == "Component catalogue"
    assert String.ends_with?(page.heading_id, "-index")
    assert page.eyebrow == "Library / Catalogue"
    assert page.uses == []
    assert page.used_by == []
  end

  describe "resolve/2" do
    test "resolves the index when no parameters are given" do
      assert_index(Page.resolve(@nodes, %{}))
    end

    test "falls back to the index for an unknown node" do
      assert_index(Page.resolve(@nodes, %{"node" => "unknown"}))
    end

    test "falls back to the index for an unknown level" do
      assert_index(Page.resolve(@nodes, %{"level" => "unknown"}))
    end

    test "resolves a chosen node with its level" do
      page = Page.resolve(@nodes, %{"node" => "button"})

      assert page.node == @button
      assert page.level == :atom
      refute page.tokens?
      assert page.heading == "button"
      assert String.ends_with?(page.heading_id, "-button")
      assert page.eyebrow == "Library / Atoms"
    end

    test "resolves a level to its first node in declaration order" do
      page = Page.resolve(@nodes, %{"level" => "organism"})

      assert page.node == @table
      assert page.level == :organism
      assert page.eyebrow == "Library / Organisms"
    end

    test "keeps an empty level chosen when it has no nodes" do
      page = Page.resolve(@nodes, %{"level" => "template"})

      assert page.node == nil
      assert page.level == :template
      assert page.heading == "Component catalogue"
      assert page.eyebrow == "Library / Templates"
    end

    test "a chosen node wins over a chosen level" do
      page = Page.resolve(@nodes, %{"node" => "button", "level" => "organism"})

      assert page.node == @button
      assert page.level == :atom
    end

    test "resolves the tokens section" do
      page = Page.resolve(@nodes, %{"section" => "tokens"})

      assert page.tokens?
      assert page.heading == "Tokens"
      assert String.ends_with?(page.heading_id, "-tokens")
      assert page.eyebrow == "Library / Tokens"
    end

    test "lists the nodes a node uses" do
      assert Page.resolve(@nodes, %{"node" => "field"}).uses == [@button]
      assert Page.resolve(@nodes, %{"node" => "button"}).uses == []
    end

    test "lists the nodes that use a node" do
      assert Page.resolve(@nodes, %{"node" => "button"}).used_by == [@field]
      assert Page.resolve(@nodes, %{"node" => "field"}).used_by == []
    end
  end

  test "node_path/2 links to a node under the catalogue path" do
    assert Page.node_path("/ui", @button) == "/ui?node=button"
  end

  describe "usage/1" do
    test "reads the component's function documentation" do
      node = %Node{
        id: :marker,
        level: :atom,
        module: Example.Catalogue.Components,
        function: :marker,
        purpose: "Marks."
      }

      assert Page.usage(node) =~ ~r/\AA synthetic extension with a visible name\./
    end

    test "reports missing documentation" do
      node = %{@button | module: :no_such_module}

      assert Page.usage(node) == "No usage documentation available."
    end
  end
end
