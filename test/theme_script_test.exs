defmodule Armature.ThemeScriptTest do
  # armature-theme.js enhances theme switches on pages without a LiveView
  # socket. These tests hold the contract between the script, the markup it
  # looks for and the package that ships it.
  use ExUnit.Case, async: true
  use Phoenix.Component
  import Phoenix.LiveViewTest
  alias Armature.Components, as: C

  @script_path Path.expand("../priv/static/armature-theme.js", __DIR__)
  @script File.read!(@script_path)

  test "the script ships in the Hex package" do
    files = Mix.Project.config()[:package][:files]
    assert "priv" in files
    assert File.regular?(@script_path)
  end

  test "the script finds switches by the attribute the component renders" do
    assert @script =~ "form[data-armature-theme-switch]"
    assert @script =~ "select[name='theme']"
    assert @script =~ ~s("data-armature-theme")
    assert @script =~ "[data-phx-session]"
  end

  test "the script stays within a strict content security policy" do
    for forbidden <- [~r/\beval\s*\(/, ~r/new\s+Function/, ~r/\.style\b/, ~r/innerHTML/] do
      refute @script =~ forbidden, "armature-theme.js matches #{inspect(forbidden)}"
    end

    refute @script =~ ~r/setAttribute\(\s*["']style/
  end

  test "a controller-rendered switch carries the script's hooks and no LiveView bindings" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.theme_switch id="theme" value="dark" />
        """
      end)

    assert present?(doc, "form#theme.armature-theme-switch[data-armature-theme-switch]")
    assert present?(doc, "#theme select[name=theme] option[value=dark][selected]")
    assert present?(doc, "#theme label[for=theme-choice]")
    refute present?(doc, "#theme[phx-change], #theme[phx-submit]")
  end

  test "a LiveView switch keeps its event bindings and the same hooks" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.theme_switch id="theme" event="theme" />
        """
      end)

    assert present?(
             doc,
             "form#theme[data-armature-theme-switch][phx-change=theme][phx-submit=theme]"
           )
  end

  defp document(component) do
    component |> render_component(%{}) |> LazyHTML.from_fragment()
  end

  defp present?(doc, selector), do: doc |> LazyHTML.query(selector) |> LazyHTML.to_tree() != []
end
