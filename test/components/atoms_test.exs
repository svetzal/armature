defmodule Armature.Components.AtomsTest do
  use Armature.ComponentsCase, async: true
  alias Armature.Components.Atoms

  describe "button" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Atoms.button id="save" phx-click="save">Save</Atoms.button>
          <Atoms.button id="cancel" variant="secondary" disabled type="submit">Cancel</Atoms.button>
          """
        end)

      %{doc: doc}
    end

    test "defaults to type button", %{doc: doc} do
      assert text(doc, "button#save[type=button]") == "Save"
    end

    test "keeps an explicit type", %{doc: doc} do
      assert text(doc, "button#cancel[type=submit]") == "Cancel"
    end

    test "forwards rest attributes such as phx-click", %{doc: doc} do
      assert present?(doc, "button#save[phx-click=save]")
    end

    test "applies the variant class", %{doc: doc} do
      assert present?(doc, "button#cancel.armature-button-secondary")
    end

    test "renders disabled only when asked", %{doc: doc} do
      assert present?(doc, "button#cancel[disabled]")
      refute present?(doc, "#save[disabled]")
    end

    test "renders a native button rather than a button role", %{doc: doc} do
      refute present?(doc, "[role=button]")
    end
  end

  describe "link" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Atoms.link id="href" href="/first" target="_blank">First</Atoms.link>
          <Atoms.link id="navigate" navigate="/second" replace>Second</Atoms.link>
          <Atoms.link id="patch" patch="/third">Third</Atoms.link>
          """
        end)

      %{doc: doc}
    end

    test "href links keep their target", %{doc: doc} do
      assert text(doc, "a#href[href='/first'][target='_blank']") == "First"
    end

    test "navigate links replace the history state", %{doc: doc} do
      assert text(doc, "a#navigate[data-phx-link=redirect][data-phx-link-state=replace]") ==
               "Second"
    end

    test "patch links patch to their path", %{doc: doc} do
      assert text(doc, "a#patch[data-phx-link=patch][href='/third']") == "Third"
    end
  end

  test "icons are decorative even when their supplied SVG has a title" do
    doc =
      document(fn assigns ->
        ~H"""
        <Atoms.button id="next">Next<Atoms.icon>
          <svg focusable="false"><title>Arrow</title><path d="M0 0" /></svg>
        </Atoms.icon></Atoms.button>
        """
      end)

    assert present?(doc, "#next .armature-icon[aria-hidden=true] svg")
    refute present?(doc, ".armature-icon[aria-label]")
    assert text(doc, "#next") =~ "Next"
  end

  describe "standalone controls" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Atoms.input id="name" name="name" value="Example" aria-label="Name" required />
          <Atoms.select
            id="choice"
            name="choice"
            value="second"
            options={[{"First", "first"}, {"Second", "second"}]}
            prompt="Choose"
            aria-label="Choice"
            disabled
          />
          <Atoms.textarea id="notes" name="notes" value="Some notes" aria-label="Notes" readonly />
          <Atoms.input
            id="accepted"
            type="checkbox"
            name="accepted"
            value="yes"
            checked
            aria-label="Accept"
          />
          <Atoms.input id="disabled" disabled aria-label="Disabled" />
          <Atoms.textarea id="disabled-notes" disabled aria-label="Disabled notes" />
          """
        end)

      %{doc: doc}
    end

    test "input keeps its value", %{doc: doc} do
      assert present?(doc, "input#name[value=Example]")
    end

    test "input keeps its required state", %{doc: doc} do
      assert present?(doc, "input#name[required]")
    end

    test "each control keeps its accessible name", %{doc: doc} do
      assert present?(doc, "input#name[aria-label=Name]")
      assert present?(doc, "select#choice[aria-label=Choice]")
      assert present?(doc, "textarea#notes[aria-label=Notes]")
    end

    test "select marks the current value selected", %{doc: doc} do
      assert present?(doc, "select#choice option[value=second][selected]")
    end

    test "select renders the prompt as the empty option", %{doc: doc} do
      assert text(doc, "#choice option[value='']") == "Choose"
    end

    test "select renders disabled when asked", %{doc: doc} do
      assert present?(doc, "select#choice[disabled]")
    end

    test "textarea keeps its readonly state", %{doc: doc} do
      assert present?(doc, "textarea#notes[readonly]")
    end

    test "textarea renders its content", %{doc: doc} do
      assert text(doc, "textarea#notes") == "Some notes"
    end

    test "controls add no ARIA textbox or combobox roles", %{doc: doc} do
      refute present?(doc, "[role=textbox], [role=combobox]")
    end

    test "checkbox input keeps its submitted value apart from its checked state", %{doc: doc} do
      assert present?(doc, "input#accepted[type=checkbox][value=yes][checked][aria-label=Accept]")
    end

    test "disabled text controls render disabled", %{doc: doc} do
      assert present?(doc, "input#disabled[disabled]")
      assert present?(doc, "textarea#disabled-notes[disabled]")
    end
  end

  test "all status tones convey their meaning in text without becoming live regions" do
    for tone <- ~w(neutral success warning error) do
      doc =
        document(
          fn assigns ->
            ~H"""
            <Atoms.status id="state" label="Needs review" tone={@tone} />
            """
          end,
          %{tone: tone}
        )

      assert text(doc, "span#state.armature-tone-#{tone}") == "Needs review"
      refute present?(doc, "[role], [aria-live]")
    end
  end
end
