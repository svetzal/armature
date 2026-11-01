defmodule Armature.ComponentsCase do
  @moduledoc false
  # Shared imports and markup queries for the baseline component tests, which
  # are split by level under test/components/.
  use ExUnit.CaseTemplate
  import ExUnit.Assertions
  import Armature.MarkupHelpers

  using do
    quote do
      use Phoenix.Component
      import Phoenix.LiveViewTest
      import Armature.MarkupHelpers
      import Armature.ComponentsCase
    end
  end

  def text(doc, selector),
    do: doc |> LazyHTML.query(selector) |> LazyHTML.text() |> String.trim()

  def children(doc, selector) do
    [{_, _, children}] = doc |> LazyHTML.query(selector) |> LazyHTML.to_tree()
    Enum.reject(children, &(is_binary(&1) and String.trim(&1) == ""))
  end

  def attribute(doc, selector, name) do
    [{_, attributes, _}] = doc |> LazyHTML.query(selector) |> LazyHTML.to_tree()
    {^name, value} = List.keyfind(attributes, name, 0)
    value
  end

  def assert_descriptions_exist(doc, selector) do
    for id <- doc |> attribute(selector, "aria-describedby") |> String.split() do
      assert present?(doc, "##{id}")
    end
  end

  def slot_attrs(component, slot) do
    component
    |> declaration()
    |> Map.fetch!(:slots)
    |> Enum.find(&(&1.name == slot))
    |> Map.fetch!(:attrs)
    |> Enum.map(&{&1.name, &1.type, &1.required})
  end

  def declared_attrs(component, names) do
    for attr <- component |> declaration() |> Map.fetch!(:attrs),
        attr.name in names,
        do: {attr.name, attr.type, attr.required, Keyword.get(attr.opts, :default)}
  end

  def rest_include(component) do
    component
    |> declaration()
    |> Map.fetch!(:attrs)
    |> Enum.find(&(&1.name == :rest))
    |> Map.fetch!(:opts)
    |> Keyword.fetch!(:include)
  end

  # Component names are unique across the level modules the registry lists.
  defp declaration(component) do
    Enum.find_value(Armature.UI.Registry.modules(), fn module ->
      Map.get(module.__components__(), component)
    end) || raise ArgumentError, "unknown component #{inspect(component)}"
  end
end
