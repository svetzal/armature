defmodule Example.UI.Consumer do
  @moduledoc false
  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]
  import Armature.Components

  def example(assigns) do
    ~H"""
    <.form for={@form} id="example-form">
      <.stack>
        <.field field={@form[:name]} label="Name" hint="Use a short name." />
        <.cluster>
          <.button type="submit">Save</.button>
          <.link href="/">Return</.link>
        </.cluster>
      </.stack>
    </.form>
    """
  end
end

defmodule Armature.ComponentsTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  import Phoenix.LiveViewTest
  alias Armature.Components, as: C

  test "the documented consumer imports render the example form" do
    doc =
      document(&Example.UI.Consumer.example/1, %{
        form: to_form(%{"name" => "Example"}, as: :sample)
      })

    assert present?(doc, "form#example-form input#sample_name[value=Example]")
    assert present?(doc, "#example-form button.armature-button[type=submit]")
    assert text(doc, "#example-form a.armature-link[href='/']") == "Return"
  end

  test "buttons have native names, default type, variants, disabled state and rest attributes" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.button id="save" phx-click="save">Save</C.button>
        <C.button id="cancel" variant="secondary" disabled type="submit">Cancel</C.button>
        """
      end)

    assert text(doc, "button#save[type=button][phx-click=save]") == "Save"
    assert text(doc, "button#cancel.armature-button-secondary[disabled][type=submit]") == "Cancel"
    refute present?(doc, "#save[disabled]")
    refute present?(doc, "[role=button]")
  end

  test "links preserve native navigation, patching and href with visible names" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.link id="href" href="/first" target="_blank">First</C.link>
        <C.link id="navigate" navigate="/second" replace>Second</C.link>
        <C.link id="patch" patch="/third">Third</C.link>
        """
      end)

    assert text(doc, "a#href[href='/first'][target='_blank']") == "First"

    assert text(doc, "a#navigate[data-phx-link=redirect][data-phx-link-state=replace]") ==
             "Second"

    assert text(doc, "a#patch[data-phx-link=patch][href='/third']") == "Third"
  end

  test "icons are decorative even when their supplied SVG has a title" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.button id="next">Next<C.icon>
          <svg focusable="false"><title>Arrow</title><path d="M0 0" /></svg>
        </C.icon></C.button>
        """
      end)

    assert present?(doc, "#next .armature-icon[aria-hidden=true] svg")
    refute present?(doc, ".armature-icon[aria-label]")
    assert text(doc, "#next") =~ "Next"
  end

  test "standalone controls are native, named, disabled and preserve values" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.input id="name" name="name" value="Example" aria-label="Name" required />
        <C.select
          id="choice"
          name="choice"
          value="second"
          options={[{"First", "first"}, {"Second", "second"}]}
          prompt="Choose"
          aria-label="Choice"
          disabled
        />
        <C.textarea id="notes" name="notes" value="Some notes" aria-label="Notes" readonly />
        """
      end)

    assert present?(doc, "input#name[aria-label=Name][value=Example][required]")

    assert present?(
             doc,
             "select#choice[aria-label=Choice][disabled] option[value=second][selected]"
           )

    assert text(doc, "#choice option[value='']") == "Choose"
    assert text(doc, "textarea#notes[aria-label=Notes][readonly]") == "Some notes"
    refute present?(doc, "[role=textbox], [role=combobox]")
  end

  test "checkbox inputs preserve their submitted value separately from checked state" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.input id="accepted" type="checkbox" name="accepted" value="yes" checked aria-label="Accept" />
        <C.input id="disabled" disabled aria-label="Disabled" />
        <C.textarea id="disabled-notes" disabled aria-label="Disabled notes" />
        """
      end)

    assert present?(doc, "input#accepted[type=checkbox][value=yes][checked][aria-label=Accept]")
    assert present?(doc, "input#disabled[disabled]")
    assert present?(doc, "textarea#disabled-notes[disabled]")
  end

  test "all status tones convey their meaning in text without becoming live regions" do
    for tone <- ~w(neutral success warning error) do
      doc =
        document(
          fn assigns ->
            ~H"""
            <C.status id="state" label="Needs review" tone={@tone} />
            """
          end,
          %{tone: tone}
        )

      assert text(doc, "span#state.armature-tone-#{tone}") == "Needs review"
      refute present?(doc, "[role], [aria-live]")
    end
  end

  test "field binds a visible label, hint, errors and preserved descriptions for every control" do
    for type <- ~w(text select textarea) do
      doc =
        document(
          fn assigns ->
            ~H"""
            <p id="external">Supporting text</p>
            <C.field
              id="sample"
              name="sample"
              value="first"
              label="Sample"
              type={@type}
              hint="A hint"
              errors={["Check this value"]}
              aria-describedby="external sample-hint"
              options={[{"First", "first"}]}
            />
            """
          end,
          %{type: type}
        )

      tag = if type == "text", do: "input", else: type
      assert text(doc, "label[for=sample]") == "Sample"
      assert present?(doc, "#{tag}#sample[name=sample][aria-invalid=true]")
      assert attribute(doc, "#sample", "aria-describedby") == "external sample-hint sample-errors"
      assert_descriptions_exist(doc, "#sample")
      assert text(doc, "#sample-errors") == "Check this value"
    end
  end

  test "valid fields omit invalid state and absent description ids, overriding caller invalid state" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.field id="valid" name="valid" label="Valid" aria-invalid="true" />
        <C.field id="hinted" name="hinted" label="Hinted" hint="A hint" />
        <C.field id="errored" name="errored" label="Errored" errors={["Required"]} />
        """
      end)

    refute present?(doc, "#valid[aria-invalid], #valid[aria-describedby], #hinted[aria-invalid]")
    assert attribute(doc, "#hinted", "aria-describedby") == "hinted-hint"
    assert attribute(doc, "#errored", "aria-describedby") == "errored-errors"
    assert_descriptions_exist(doc, "#hinted")
    assert_descriptions_exist(doc, "#errored")
  end

  test "FormField errors appear only for used inputs and are translated by the caller" do
    for {params, invalid?} <- [
          {%{"name" => "", "_unused_name" => ""}, false},
          {%{"name" => ""}, true}
        ] do
      form =
        to_form(params, as: :sample, errors: [name: {"needs %{count} characters", [count: 2]}])

      translate = fn {message, options} ->
        String.replace(message, "%{count}", to_string(options[:count]))
      end

      doc =
        document(
          fn assigns ->
            ~H"""
            <C.field field={@form[:name]} label="Name" hint="A hint" translate_error={@translate} />
            """
          end,
          %{form: form, translate: translate}
        )

      assert present?(doc, "input#sample_name[name='sample[name]']")
      assert text(doc, "label[for=sample_name]") == "Name"
      assert present?(doc, "#sample_name[aria-invalid=true]") == invalid?
      assert present?(doc, "#sample_name-errors") == invalid?
      if invalid?, do: assert(text(doc, "#sample_name-errors") == "needs 2 characters")
      assert_descriptions_exist(doc, "#sample_name")
    end
  end

  test "FormField values, default error messages and explicit overrides are preserved" do
    form = to_form(%{"name" => "First"}, as: :sample, errors: [name: {"Invalid", []}])

    doc =
      document(
        fn assigns ->
          ~H"""
          <C.field field={@form[:name]} label="Name" />
          <C.field field={@form[:name]} id="override" name="other" value="Second" label="Other" />
          <C.field
            field={@form[:name]}
            id="multi"
            type="select"
            multiple
            label="Choices"
            options={[{"First", "First"}]}
          />
          """
        end,
        %{form: form}
      )

    assert present?(doc, "#sample_name[value=First]")
    assert text(doc, "#sample_name-errors") == "Invalid"
    assert present?(doc, "#override[name=other][value=Second]")
    assert present?(doc, "select#multi[multiple][name='sample[name][]']")
  end

  test "plain fields require a stable id" do
    assert_raise ArgumentError, ~r/requires an id/, fn ->
      render_component(&C.field/1, label: "Name", name: "name")
    end
  end

  test "notices announce results with appropriate roles and keep static guidance quiet" do
    for tone <- ~w(neutral success warning error), result <- [false, true] do
      doc =
        document(
          fn assigns ->
            ~H"""
            <C.notice id="feedback" tone={@tone} result={@result} title="Outcome">
              Explained in words
              <:actions><C.button id="continue">Continue</C.button></:actions>
            </C.notice>
            """
          end,
          %{tone: tone, result: result}
        )

      if result do
        role = if tone == "error", do: "alert", else: "status"
        assert present?(doc, "#feedback[role=#{role}][aria-atomic=true]")
      else
        refute present?(doc, "#feedback[role], #feedback[aria-live], #feedback[aria-atomic]")
      end

      assert text(doc, ".armature-notice-title") == "Outcome"
      assert text(doc, "button#continue[type=button]") == "Continue"
    end
  end

  test "notices can omit their title and actions" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.notice id="guidance">Supporting information</C.notice>
        """
      end)

    refute present?(doc, ".armature-notice-title, .armature-notice-actions")
    assert text(doc, "#guidance") == "Supporting information"
  end

  test "every layout preserves content order without adding semantic roles" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.stack id="stack">
          <p>First</p><p>Second</p>
        </C.stack>
        <C.cluster id="cluster">
          <p>First</p><p>Second</p>
        </C.cluster>
        <C.grid id="grid">
          <p>First</p><p>Second</p>
        </C.grid>
        <C.split id="split">
          <p>First</p><:secondary>
            <p>Second</p>
          </:secondary>
        </C.split>
        """
      end)

    for name <- ~w(stack cluster grid split) do
      assert present?(doc, "div##{name}.armature-#{name}")

      assert doc
             |> LazyHTML.query("##{name} p")
             |> LazyHTML.to_tree()
             |> Enum.map(fn {_, _, [content]} -> content end) == ["First", "Second"]
    end

    refute present?(doc, "[role], aside, section, main")
  end

  defp document(component, assigns \\ %{}) do
    component |> render_component(assigns) |> LazyHTML.from_fragment()
  end

  defp present?(doc, selector), do: doc |> LazyHTML.query(selector) |> LazyHTML.to_tree() != []

  defp text(doc, selector),
    do: doc |> LazyHTML.query(selector) |> LazyHTML.text() |> String.trim()

  defp attribute(doc, selector, name) do
    [{_, attributes, _}] = doc |> LazyHTML.query(selector) |> LazyHTML.to_tree()
    {^name, value} = List.keyfind(attributes, name, 0)
    value
  end

  defp assert_descriptions_exist(doc, selector) do
    for id <- doc |> attribute(selector, "aria-describedby") |> String.split() do
      assert present?(doc, "##{id}")
    end
  end
end
