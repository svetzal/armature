defmodule Armature.ThemeScriptTest do
  # armature-theme.js enhances theme switches on pages without a LiveView
  # socket. These tests hold the contract between the script, the markup it
  # looks for and the package that ships it.
  use ExUnit.Case, async: true
  use Phoenix.Component
  import Armature.MarkupHelpers
  alias Armature.Components, as: C

  @script_path Path.expand("../priv/static/armature-theme.js", __DIR__)

  test "the script ships in the Hex package" do
    files = Mix.Project.config()[:package][:files]
    assert "priv" in files
    assert File.regular?(@script_path)
  end

  test "a controller-rendered switch carries the script's hooks and no LiveView bindings" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.theme_switch id="theme" value="dark" />
        """
      end)

    assert present?(doc, "form#theme.armature-theme-switch[data-armature-theme-switch]")
    assert present?(doc, "#theme input[type=radio][name=theme][value=dark][checked]")
    assert present?(doc, "#theme fieldset > legend")
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
end
