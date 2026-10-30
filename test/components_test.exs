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
  import Armature.MarkupHelpers
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

  describe "button" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.button id="save" phx-click="save">Save</C.button>
          <C.button id="cancel" variant="secondary" disabled type="submit">Cancel</C.button>
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
          <C.link id="href" href="/first" target="_blank">First</C.link>
          <C.link id="navigate" navigate="/second" replace>Second</C.link>
          <C.link id="patch" patch="/third">Third</C.link>
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
        <C.button id="next">Next<C.icon>
          <svg focusable="false"><title>Arrow</title><path d="M0 0" /></svg>
        </C.icon></C.button>
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
          <C.input id="accepted" type="checkbox" name="accepted" value="yes" checked aria-label="Accept" />
          <C.input id="disabled" disabled aria-label="Disabled" />
          <C.textarea id="disabled-notes" disabled aria-label="Disabled notes" />
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
            <C.status id="state" label="Needs review" tone={@tone} />
            """
          end,
          %{tone: tone}
        )

      assert text(doc, "span#state.armature-tone-#{tone}") == "Needs review"
      refute present?(doc, "[role], [aria-live]")
    end
  end

  describe "field with hint and errors" do
    setup do
      docs =
        for type <- ~w(text select textarea), into: %{} do
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
          {tag, doc}
        end

      %{docs: docs}
    end

    test "binds a visible label to the control", %{docs: docs} do
      for {_tag, doc} <- docs, do: assert(text(doc, "label[for=sample]") == "Sample")
    end

    test "marks the control invalid when errors exist", %{docs: docs} do
      for {tag, doc} <- docs do
        assert present?(doc, "#{tag}#sample[name=sample][aria-invalid=true]")
      end
    end

    test "appends the errors id to the caller's aria-describedby", %{docs: docs} do
      for {_tag, doc} <- docs do
        assert attribute(doc, "#sample", "aria-describedby") ==
                 "external sample-hint sample-errors"
      end
    end

    test "every described-by id exists in the document", %{docs: docs} do
      for {_tag, doc} <- docs, do: assert_descriptions_exist(doc, "#sample")
    end

    test "renders the error text", %{docs: docs} do
      for {_tag, doc} <- docs, do: assert(text(doc, "#sample-errors") == "Check this value")
    end
  end

  describe "field descriptions" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.field id="valid" name="valid" label="Valid" aria-invalid="true" />
          <C.field id="hinted" name="hinted" label="Hinted" hint="A hint" />
          <C.field id="errored" name="errored" label="Errored" errors={["Required"]} />
          """
        end)

      %{doc: doc}
    end

    test "a valid field carries neither invalid state nor description", %{doc: doc} do
      refute present?(doc, "#valid[aria-invalid], #valid[aria-describedby]")
    end

    test "a hinted field without errors is not invalid", %{doc: doc} do
      refute present?(doc, "#hinted[aria-invalid]")
    end

    test "a hinted field is described by its hint", %{doc: doc} do
      assert attribute(doc, "#hinted", "aria-describedby") == "hinted-hint"
      assert_descriptions_exist(doc, "#hinted")
    end

    test "an errored field is described by its errors", %{doc: doc} do
      assert attribute(doc, "#errored", "aria-describedby") == "errored-errors"
      assert_descriptions_exist(doc, "#errored")
    end
  end

  describe "FormField errors" do
    test "derive the input identity from the form field" do
      for params <- [%{"name" => "", "_unused_name" => ""}, %{"name" => ""}] do
        doc = translated_form_field_document(params)
        assert present?(doc, "input#sample_name[name='sample[name]']")
        assert text(doc, "label[for=sample_name]") == "Name"
      end
    end

    test "are hidden for unused inputs" do
      doc = translated_form_field_document(%{"name" => "", "_unused_name" => ""})

      refute present?(doc, "#sample_name[aria-invalid=true]")
      refute present?(doc, "#sample_name-errors")
      assert_descriptions_exist(doc, "#sample_name")
    end

    test "are shown translated for used inputs" do
      doc = translated_form_field_document(%{"name" => ""})

      assert present?(doc, "#sample_name[aria-invalid=true]")
      assert text(doc, "#sample_name-errors") == "needs 2 characters"
      assert_descriptions_exist(doc, "#sample_name")
    end
  end

  describe "FormField attributes" do
    setup do
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

      %{doc: doc}
    end

    test "take the value from the form", %{doc: doc} do
      assert present?(doc, "#sample_name[value=First]")
    end

    test "show the default error message", %{doc: doc} do
      assert text(doc, "#sample_name-errors") == "Invalid"
    end

    test "yield to explicit attributes", %{doc: doc} do
      assert present?(doc, "#override[name=other][value=Second]")
    end

    test "suffix a multiple select name with brackets", %{doc: doc} do
      assert present?(doc, "select#multi[multiple][name='sample[name][]']")
    end
  end

  describe "checkbox field" do
    @checkbox_values [
      {true, true},
      {"true", true},
      {false, false},
      {"false", false},
      {nil, false}
    ]

    test "checked state follows the form value" do
      for {value, checked?} <- @checkbox_values do
        doc = checkbox_field_document(value)
        assert present?(doc, "input#sample_accepted[checked]") == checked?
      end
    end

    test "the box submits true" do
      for {value, _checked?} <- @checkbox_values do
        doc = checkbox_field_document(value)
        assert present?(doc, "input#sample_accepted[type=checkbox][value=true]")
      end
    end

    test "places a hidden false before the box" do
      for {value, _checked?} <- @checkbox_values do
        doc = checkbox_field_document(value)

        [hidden, box] =
          doc |> LazyHTML.query("input[name='sample[accepted]']") |> LazyHTML.to_tree()

        assert {"type", "hidden"} in elem(hidden, 1)
        assert {"value", "false"} in elem(hidden, 1)
        assert {"type", "checkbox"} in elem(box, 1)
      end
    end

    test "renders one label right after the box in one row" do
      for {value, _checked?} <- @checkbox_values do
        doc = checkbox_field_document(value)

        assert present?(
                 doc,
                 ".armature-check > input#sample_accepted + label[for=sample_accepted]"
               )

        assert doc
               |> LazyHTML.query("label[for=sample_accepted]")
               |> LazyHTML.to_tree()
               |> length() ==
                 1
      end
    end

    # What a browser sends for an unticked and a ticked box, through Plug's
    # decoder. The hidden fallback relies on the later value winning.
    test "a later checkbox value wins over the hidden false when decoded" do
      assert Plug.Conn.Query.decode("sample[accepted]=false") == %{
               "sample" => %{"accepted" => "false"}
             }

      assert Plug.Conn.Query.decode("sample[accepted]=false&sample[accepted]=true") ==
               %{"sample" => %{"accepted" => "true"}}
    end
  end

  describe "checkbox field overrides" do
    setup do
      form = to_form(%{"accepted" => false}, as: :sample)

      doc =
        document(
          fn assigns ->
            ~H"""
            <C.field field={@form[:accepted]} type="checkbox" label="Locked" disabled />
            <C.field
              field={@form[:accepted]}
              id="forced"
              type="checkbox"
              label="Forced"
              checked
            />
            """
          end,
          %{form: form}
        )

      %{doc: doc}
    end

    test "disabled checkbox fields disable their hidden fallback too", %{doc: doc} do
      assert present?(doc, "input[type=hidden][name='sample[accepted]'][disabled]")
      assert present?(doc, "input#sample_accepted[type=checkbox][disabled]")
    end

    test "an explicit checked attribute wins over the form value", %{doc: doc} do
      assert present?(doc, "input#forced[type=checkbox][checked]")
    end
  end

  test "plain fields require a stable id" do
    assert_raise ArgumentError, ~r/requires an id/, fn ->
      render_component(&C.field/1, label: "Name", name: "name")
    end
  end

  describe "notice" do
    @notice_tones ~w(neutral success warning error)

    test "error results use role alert" do
      doc = notice_document("error", true)
      assert present?(doc, "#feedback[role=alert][aria-atomic=true]")
    end

    test "non-error results use role status" do
      for tone <- @notice_tones -- ["error"] do
        doc = notice_document(tone, true)
        assert present?(doc, "#feedback[role=status][aria-atomic=true]")
      end
    end

    test "static guidance carries no live region" do
      for tone <- @notice_tones do
        doc = notice_document(tone, false)
        refute present?(doc, "#feedback[role], #feedback[aria-live], #feedback[aria-atomic]")
      end
    end

    test "renders the title" do
      for tone <- @notice_tones, result <- [false, true] do
        doc = notice_document(tone, result)
        assert text(doc, ".armature-notice-title") == "Outcome"
      end
    end

    test "renders actions" do
      for tone <- @notice_tones, result <- [false, true] do
        doc = notice_document(tone, result)
        assert text(doc, "button#continue[type=button]") == "Continue"
      end
    end
  end

  test "notices render without a title or actions" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.notice id="guidance">Supporting information</C.notice>
        """
      end)

    refute present?(doc, ".armature-notice-title, .armature-notice-actions")
    assert text(doc, "#guidance") == "Supporting information"
  end

  describe "layouts" do
    setup do
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

  describe "data_table sorting" do
    test "marks only the heading sorted by sort_by with aria-sort" do
      for sort_by <- ~w(name score), direction <- ~w(asc desc) do
        doc = sortable_records_document(sort_by, direction)
        [inactive] = ~w(name score) -- [sort_by]

        assert present?(doc, "th[aria-sort] button[phx-value-key=#{sort_by}]")
        assert present?(doc, "th:not([aria-sort]) button[phx-value-key=#{inactive}]")
        refute present?(doc, "th[aria-sort] button[phx-value-key=#{inactive}]")
        assert length(LazyHTML.to_tree(LazyHTML.query(doc, "th[aria-sort]"))) == 1
      end
    end

    test "reports ascending or descending on the sorted heading" do
      for sort_by <- ~w(name score),
          {direction, aria_sort} <- [{"asc", "ascending"}, {"desc", "descending"}] do
        doc = sortable_records_document(sort_by, direction)
        assert attribute(doc, "th[aria-sort]", "aria-sort") == aria_sort
      end
    end

    test "shows a decorative sort hint only on unsorted sortable headings" do
      for sort_by <- ~w(name score), direction <- ~w(asc desc) do
        doc = sortable_records_document(sort_by, direction)
        [inactive] = ~w(name score) -- [sort_by]

        assert present?(
                 doc,
                 "button[phx-value-key=#{inactive}] .armature-sort-hint[aria-hidden=true]"
               )

        refute present?(doc, "th[aria-sort] .armature-sort-hint")
      end
    end

    test "sort buttons are named after their column" do
      for sort_by <- ~w(name score), direction <- ~w(asc desc) do
        doc = sortable_records_document(sort_by, direction)

        assert present?(
                 doc,
                 "th button[type=button][phx-value-key=name][aria-label='Sort by Name']"
               )

        assert present?(
                 doc,
                 "th button[type=button][phx-value-key=score][aria-label='Sort by Score']"
               )
      end
    end

    test "sort buttons send the sort event with the column key" do
      for sort_by <- ~w(name score), direction <- ~w(asc desc) do
        doc = sortable_records_document(sort_by, direction)

        assert present?(doc, "th button[phx-click=order][phx-value-key=name]")
        assert present?(doc, "th button[phx-click=order][phx-value-key=score]")
      end
    end
  end

  describe "data_table selection" do
    setup do
      %{doc: sortable_records_document("name", "asc")}
    end

    test "labels the caption", %{doc: doc} do
      assert text(doc, "table caption") == "Example records"
    end

    test "exposes a keyboard-reachable scroll region named after the caption", %{doc: doc} do
      assert present?(
               doc,
               "#records-scroll[tabindex='0'][role=region][aria-label='Example records']"
             )
    end

    test "renders one column header per column with scope col", %{doc: doc} do
      assert length(LazyHTML.to_tree(LazyHTML.query(doc, "th[scope=col]"))) == 2
      assert doc |> LazyHTML.query("thead th") |> Enum.count() == 2
    end

    test "marks numeric columns throughout", %{doc: doc} do
      assert present?(doc, "th.armature-numeric button[phx-value-key=score]")
      assert present?(doc, "td.armature-numeric")
    end

    test "presses the selected row label", %{doc: doc} do
      assert present?(doc, "button[phx-click=choose][phx-value-id=R-1][aria-pressed=true]")
    end

    test "points the row label at the inspector", %{doc: doc} do
      assert present?(doc, "button[phx-value-id=R-1][aria-controls=details]")
    end

    test "leaves unselected rows unpressed", %{doc: doc} do
      assert present?(doc, "button[phx-value-id=R-2][aria-pressed=false]")
    end

    test "names the row button by its visible text", %{doc: doc} do
      assert text(doc, "#records-R-1 .armature-row-select") == "Example"
      refute present?(doc, "tbody button[aria-label]")
    end

    test "renders one selection button per row", %{doc: doc} do
      assert doc |> LazyHTML.query("#records-R-1 td") |> Enum.count() == 2
      assert doc |> LazyHTML.query("#records-R-1 button") |> Enum.count() == 1
    end

    test "makes the whole row clickable for selection", %{doc: doc} do
      assert present?(doc, "#records-R-1.armature-clickable-row[phx-click=choose]")
    end

    test "inspector is labelled by its heading", %{doc: doc} do
      assert present?(doc, "aside#details[aria-labelledby=details-heading]")
      assert text(doc, "#details-heading") == "Record details"
    end

    test "inspector is not a live region", %{doc: doc} do
      refute present?(doc, "aside[aria-live], aside[role=status]")
    end
  end

  describe "selectable table validation" do
    test "rejects a missing row label" do
      assert_raise ArgumentError, "selectable tables require exactly one row_label column", fn ->
        invalid_selectable_table_document([])
      end
    end

    test "rejects two row labels" do
      assert_raise ArgumentError, "selectable tables require exactly one row_label column", fn ->
        invalid_selectable_table_document([%{row_label: true}, %{row_label: true}])
      end
    end

    test "rejects an interactive column alongside selection" do
      assert_raise ArgumentError, ~r/selectable rows allow only the row-label button/, fn ->
        document(fn assigns ->
          ~H"""
          <C.data_table
            id="actions"
            rows={[%{id: "R-1"}]}
            caption="Records"
            select_event="choose"
            inspector_id="details"
          >
            <:col :let={row} label="Identifier" row_label>{row.id}</:col>
            <:col label="Actions" interactive><C.link href="/record">Open</C.link></:col>
          </C.data_table>
          """
        end)
      end
    end
  end

  describe "responsive composition" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.app_shell
            id="responsive-shell"
            title="Library"
            heading="Overview"
            heading_id="responsive-heading"
            context="Library"
            items={[]}
          >
            <C.grouped_nav id="responsive-nav" label="Components" event="choose" groups={[]} />
            <C.grid id="responsive-panels">
              <C.panel id="first-panel" heading="First">Content</C.panel>
              <C.panel id="second-panel" heading="Second">Content</C.panel>
            </C.grid>
          </C.app_shell>
          """
        end)

      %{doc: doc}
    end

    test "grouped navigation renders inside the shell content", %{doc: doc} do
      assert present?(doc, "#responsive-shell .armature-app-shell-content #responsive-nav")
    end

    test "grouped navigation keeps its native picker", %{doc: doc} do
      assert present?(doc, "#responsive-nav > .armature-grouped-nav-picker")
    end

    test "panels render inside the grid items", %{doc: doc} do
      assert present?(doc, "#responsive-panels > .armature-grid-items > #first-panel")
    end

    test "panels are labelled by their headings", %{doc: doc} do
      assert present?(doc, "#second-panel[aria-labelledby=second-panel-heading]")
    end

    test "a composition keeps a single main landmark", %{doc: doc} do
      assert doc |> LazyHTML.query("main") |> Enum.count() == 1
    end
  end

  test "tables without selection render rows that have no identifier" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.data_table
          id="totals"
          rows={[%{name: "First", total: 3}, %{name: "Second", total: 5}, [name: "Third", total: 8]]}
          caption="Totals"
        >
          <:col :let={row} label="Name">{row[:name]}</:col>
          <:col :let={row} label="Total" numeric>{row[:total]}</:col>
        </C.data_table>
        """
      end)

    assert text(doc, "#totals-row-0 td:first-child") == "First"
    assert text(doc, "#totals-row-2 td:first-child") == "Third"
    assert doc |> LazyHTML.query("tbody tr") |> Enum.count() == 3
    refute present?(doc, "tr[phx-click], [phx-value-id]")
  end

  describe "row ids without selection" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.data_table id="by-id" rows={[%{id: "R-1"}]} caption="Records">
            <:col :let={row} label="Identifier">{row.id}</:col>
          </C.data_table>
          <C.data_table id="by-key" rows={[%{key: "K-1"}]} row_id={& &1.key} caption="Records">
            <:col :let={row} label="Key">{row.key}</:col>
          </C.data_table>
          """
        end)

      %{doc: doc}
    end

    test "rows keep ids from their id field", %{doc: doc} do
      assert present?(doc, "tr#by-id-R-1")
    end

    test "rows take ids from row_id", %{doc: doc} do
      assert present?(doc, "tr#by-key-K-1")
    end
  end

  test "selectable tables need a row identifier" do
    assert_raise ArgumentError, ~r/selectable tables need a row identifier/, fn ->
      document(fn assigns ->
        ~H"""
        <C.data_table
          id="unidentified"
          rows={[%{name: "First"}]}
          caption="Records"
          select_event="choose"
          inspector_id="details"
        >
          <:col :let={row} label="Name" row_label>{row.name}</:col>
        </C.data_table>
        """
      end)
    end
  end

  test "selection requires an inspector destination" do
    assert_raise ArgumentError, "selection requires an existing inspector_id", fn ->
      document(&C.data_table/1, %{
        id: "records",
        rows: [],
        caption: "Records",
        select_event: "select"
      })
    end
  end

  test "tables without a sort event render no sort buttons" do
    for rows <- [[], [%{id: "R-1", name: "Example"}]] do
      refute present?(plain_table_document(rows), "button, th[aria-sort]")
    end
  end

  test "a hidden caption stays in the document for screen readers" do
    doc = plain_table_document([%{id: "R-1", name: "Example"}])

    assert present?(doc, "caption.armature-sr-only")
    assert present?(doc, "th[scope=col]")
  end

  test "empty tables explain the absence in words" do
    doc = plain_table_document([])

    refute present?(doc, "table")
    assert text(doc, "#plain-empty") == "No records to display."
  end

  describe "table_toolbar" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.table_toolbar
            id="tools"
            search_label="Find records"
            search_event="search"
            query="Example"
            total={200}
          >
            <:actions><C.button>Export</C.button></:actions>
          </C.table_toolbar>
          """
        end)

      %{doc: doc}
    end

    test "binds its label to the search input", %{doc: doc} do
      assert text(doc, "label[for=tools-search]") == "Find records"
    end

    test "search form sends the search event with the query value", %{doc: doc} do
      assert present?(
               doc,
               "form#tools-search-form[phx-change=search] input#tools-search[type=search][name=query][value=Example]"
             )
    end

    test "count is a polite atomic status", %{doc: doc} do
      assert text(doc, "#tools-count[role=status][aria-live=polite][aria-atomic=true]") ==
               "200 results"
    end

    test "renders caller actions", %{doc: doc} do
      assert text(doc, ".armature-toolbar-actions button") == "Export"
    end
  end

  describe "pagination" do
    @page_boundaries [
      {1, 80, 1, 25, 2000, true, false},
      {2, 80, 26, 50, 2000, false, false},
      {80, 80, 1976, 2000, 2000, false, true},
      {1, 1, 0, 0, 0, true, true}
    ]

    test "names the page navigation" do
      assert present?(pagination_document(1, 80, 1, 25, 2000), "nav[aria-label='Table pages']")
    end

    test "previous sends the preceding page number" do
      doc = pagination_document(2, 80, 26, 50, 2000)

      assert present?(
               doc,
               "button[aria-label='Previous page'][phx-click=page][phx-value-page='1']"
             )
    end

    test "next sends the following page number" do
      doc = pagination_document(2, 80, 26, 50, 2000)

      assert present?(doc, "button[aria-label='Next page'][phx-click=page][phx-value-page='3']")
    end

    test "disables previous on the first page" do
      for {page, pages, first, last, total, previous_disabled?, _next_disabled?} <-
            @page_boundaries do
        doc = pagination_document(page, pages, first, last, total)

        assert present?(doc, "button[aria-label='Previous page'][disabled]") ==
                 previous_disabled?
      end
    end

    test "disables next on the last page" do
      for {page, pages, first, last, total, _previous_disabled?, next_disabled?} <-
            @page_boundaries do
        doc = pagination_document(page, pages, first, last, total)
        assert present?(doc, "button[aria-label='Next page'][disabled]") == next_disabled?
      end
    end

    test "announces the visible range with thousands separators as a polite status" do
      for {page, pages, first, last, total, announcement} <- [
            {1, 80, 1, 25, 2000, "1–25 of 2,000"},
            {2, 80, 26, 50, 2000, "26–50 of 2,000"},
            {80, 80, 1976, 2000, 2000, "1,976–2,000 of 2,000"},
            {1, 1, 0, 0, 0, "0–0 of 0"}
          ] do
        doc = pagination_document(page, pages, first, last, total)

        assert text(doc, "#pages-range[role=status][aria-live=polite][aria-atomic=true]") ==
                 announcement
      end
    end

    test "labels the page size picker" do
      doc = pagination_document(1, 80, 1, 25, 2000)
      assert text(doc, "label[for=pages-size]") == "Records per page"
    end

    test "selects the current page size" do
      doc = pagination_document(1, 80, 1, 25, 2000)

      assert present?(
               doc,
               "form[phx-change=size] select#pages-size[name=page_size] option[value='25'][selected]"
             )
    end

    test "omits the page size picker when no sizes are given" do
      doc =
        document(&C.pagination/1, %{
          id: "one",
          page: 1,
          pages: 1,
          first: 1,
          last: 1,
          total: 1,
          page_event: "page"
        })

      refute present?(doc, "select")
    end
  end

  describe "record_header" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.record_header id="record" title="Record R-1" context="Example collection" status="Ready">
            <:actions><C.button>Update</C.button></:actions>
          </C.record_header>
          """
        end)

      %{doc: doc}
    end

    test "renders the heading", %{doc: doc} do
      assert text(doc, "header#record h2#record-heading") == "Record R-1"
    end

    test "renders the context", %{doc: doc} do
      assert text(doc, "header p") == "Example collection"
    end

    test "renders the status", %{doc: doc} do
      assert text(doc, "header .armature-status") == "Ready"
    end

    test "renders the actions", %{doc: doc} do
      assert text(doc, "header button") == "Update"
    end

    test "a minimal header renders only its heading" do
      doc = document(&C.record_header/1, %{id: "minimal", title: "Record"})
      refute present?(doc, "p, .armature-status, button")
    end
  end

  describe "table_inspector" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.table_inspector
            id="browser"
            rows={[%{id: "R-1", name: "Example"}]}
            caption="Records"
            total={1}
            page={1}
            pages={1}
            first={1}
            last={1}
            search_event="search"
            sort_event="sort"
            page_event="page"
            select_event="select"
            selected_id="R-1"
            selection_label="Selected R-1"
            inspector_title="Selected record"
            size_event="size"
            page_sizes={[10, 25, 50]}
            page_size={25}
          >
            <:col :let={row} label="Name" sort_key="name" row_label>{row.name}</:col>
            <:actions><C.button>Export</C.button></:actions>
            <:details><C.record_header id="selected" title="Record R-1" /></:details>
          </C.table_inspector>
          """
        end)

      %{doc: doc}
    end

    test "composes its workflow parts under its own id", %{doc: doc} do
      assert present?(doc, "#browser .armature-split #browser-table")
      assert present?(doc, "#browser-toolbar input[type=search]")
      assert present?(doc, "#browser-pagination nav, nav#browser-pagination")
    end

    test "selected row controls the inspector", %{doc: doc} do
      assert present?(doc, "button[aria-controls=browser-inspector][aria-pressed=true]")
    end

    test "offers a skip link to the inspector", %{doc: doc} do
      assert present?(doc, "a[href='#browser-inspector']")
    end

    test "announces the selection as a polite status", %{doc: doc} do
      assert text(doc, "#browser-selection[role=status][aria-live=polite][aria-atomic=true]") ==
               "Selected R-1"
    end

    test "inspector is focusable by script", %{doc: doc} do
      assert present?(
               doc,
               "aside#browser-inspector[tabindex='-1'][aria-labelledby=browser-inspector-heading] h2"
             )
    end

    test "nothing takes focus on render", %{doc: doc} do
      refute present?(doc, "[autofocus]")
    end

    test "inspector is not a live region", %{doc: doc} do
      refute present?(doc, "aside[aria-live]")
    end

    test "declares the same col slot attributes as data_table" do
      assert slot_attrs(:table_inspector, :col) == slot_attrs(:data_table, :col)
    end

    test "declares the paging attributes as pagination does" do
      paging = ~w(page pages first last total page_event page_size page_sizes size_event)a

      assert declared_attrs(:table_inspector, paging) == declared_attrs(:pagination, paging)
    end
  end

  describe "field forwarding" do
    test "a textarea field forwards wrap" do
      doc =
        document(fn assigns ->
          ~H|<C.field id="notes" name="notes" label="Notes" type="textarea" wrap="off" />|
        end)

      assert present?(doc, "textarea#notes[wrap=off]")
    end

    test "forwards every attribute its controls accept except multiple" do
      controls = Enum.flat_map([:input, :select, :textarea], &rest_include/1)

      assert Enum.sort(rest_include(:field)) ==
               controls |> Enum.uniq() |> List.delete("multiple") |> Enum.sort()
    end
  end

  test "facts associate each visible label with its value" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.facts>
          <:fact label="Identifier">R-001</:fact>
          <:fact label="Score">42</:fact>
        </C.facts>
        """
      end)

    assert text(doc, "dl.armature-facts > div:first-child dt") == "Identifier"
    assert text(doc, "dl.armature-facts > div:first-child dd") == "R-001"
    assert text(doc, "dl.armature-facts > div:last-child dt") == "Score"
    assert text(doc, "dl.armature-facts > div:last-child dd") == "42"
  end

  describe "toolbar search" do
    test "search icon is decorative" do
      for query <- ["", "Example"] do
        doc = toolbar_search_document(query)
        assert present?(doc, ".armature-search > .armature-icon[aria-hidden=true]")
      end
    end

    test "the clear button appears only with a query" do
      for query <- ["", "Example"] do
        doc = toolbar_search_document(query)
        assert present?(doc, "#search-clear") == (query != "")
      end
    end

    test "the clear button sends an empty query" do
      doc = toolbar_search_document("Example")

      assert present?(
               doc,
               "#search-clear[aria-label='Clear search'][phx-click=filter][phx-value-query='']"
             )
    end
  end

  test "tables render default density" do
    doc = density_document("default")

    assert present?(doc, "table#density[data-density=default]")
    assert text(doc, "#density td") == "R-001"
  end

  test "table density accepts compact" do
    doc = density_document("compact")

    assert present?(doc, "table#density[data-density=compact]")
    assert text(doc, "#density td") == "R-001"
  end

  describe "app_shell" do
    setup do
      %{doc: shell_document()}
    end

    test "skip link targets the main heading", %{doc: doc} do
      assert text(doc, "#shell > a:first-child[href='#overview']") == "Skip to main content"
    end

    test "brand link patches home with an accessible name", %{doc: doc} do
      assert present?(
               doc,
               ".armature-side-nav-brand a[href='/index'][data-phx-link=patch][aria-label='Library home']"
             )
    end

    test "main landmark is labelled by its focusable heading", %{doc: doc} do
      assert present?(doc, "main[aria-labelledby=overview] h1#overview[tabindex='-1']")
    end

    test "current item is marked inside the named main nav", %{doc: doc} do
      assert present?(doc, "nav[aria-label='Main'] #overview-link[aria-current=page]")
    end

    test "side_nav renders patch links without a false current marker", %{doc: doc} do
      assert present?(
               doc,
               "#separate-nav nav[aria-label='Example sections'] a[data-phx-link=patch]:not([aria-current])"
             )
    end

    test "top_bar names its header from context", %{doc: doc} do
      assert present?(doc, "header[aria-label='Library / Catalogue']")
    end

    test "panel is labelled by its heading", %{doc: doc} do
      assert text(doc, "#summary[aria-labelledby=summary-heading] h2") == "Summary"
    end

    test "panel renders its actions", %{doc: doc} do
      assert present?(doc, "#summary button")
    end

    test "top_actions slot renders its content", %{doc: doc} do
      assert present?(doc, ".armature-top-bar form#theme input#theme-dark[checked]")
    end

    test "footnote slot renders its content", %{doc: doc} do
      assert text(doc, ".armature-side-nav-footnote") == "Synthetic examples"
    end

    test "renders no brand mark when none is given", %{doc: doc} do
      refute present?(doc, ".armature-side-nav-mark")
    end
  end

  describe "side_nav given a mark" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.side_nav id="linked-mark" title="Library" home_patch="/index" items={[]}>
            <:mark><svg id="linked-art" viewBox="0 0 2 5"><path d="M1 0 2 5H0Z" /></svg></:mark>
          </C.side_nav>
          <C.side_nav id="plain-mark" title="Library" items={[]}>
            <:mark><svg id="plain-art" viewBox="0 0 2 5"><path d="M1 0 2 5H0Z" /></svg></:mark>
          </C.side_nav>
          <C.side_nav id="untitled-mark" subtitle="Examples" items={[]}>
            <:mark><svg id="untitled-art" viewBox="0 0 2 5"><path d="M1 0 2 5H0Z" /></svg></:mark>
          </C.side_nav>
          """
        end)

      %{doc: doc}
    end

    test "renders the mark before the title inside the home link", %{doc: doc} do
      assert [{"span", attributes, _}, title] =
               children(doc, "#linked-mark .armature-side-nav-brand > a")

      assert {"class", "armature-side-nav-mark"} in attributes
      assert String.trim(title) == "Library"
    end

    test "renders the mark before the title when the brand is not a link", %{doc: doc} do
      assert [{"span", attributes, _}, title] =
               children(doc, "#plain-mark .armature-side-nav-brand > span")

      assert {"class", "armature-side-nav-mark"} in attributes
      assert String.trim(title) == "Library"
    end

    test "renders the caller's mark content", %{doc: doc} do
      assert present?(doc, "#linked-mark .armature-side-nav-mark > svg#linked-art")
    end

    test "hides the decorative mark from assistive technology", %{doc: doc} do
      assert present?(doc, "#linked-mark .armature-side-nav-mark[aria-hidden=true]")
      assert present?(doc, "#plain-mark .armature-side-nav-mark[aria-hidden=true]")
    end

    test "keeps the title as the home link's accessible name", %{doc: doc} do
      assert attribute(doc, "#linked-mark .armature-side-nav-brand > a", "aria-label") ==
               "Library home"
    end

    test "renders no mark without a title", %{doc: doc} do
      refute present?(doc, "#untitled-art")
    end
  end

  test "an app shell forwards its mark to the side navigation brand" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.app_shell
          id="marked-shell"
          title="Library"
          heading="Overview"
          heading_id="marked-overview"
          context="Library"
          items={[%{label: "Overview", href: "/"}]}
        >
          <:mark><svg id="shell-art" viewBox="0 0 2 5"><path d="M1 0 2 5H0Z" /></svg></:mark>
          <p>Content</p>
        </C.app_shell>
        """
      end)

    assert present?(
             doc,
             "#marked-shell-rail .armature-side-nav-brand .armature-side-nav-mark > svg#shell-art"
           )
  end

  test "an app shell carries no catalogue words when the caller gives no brand or caption" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.app_shell
          id="plain-shell"
          heading="Orders"
          heading_id="orders"
          context="Orders"
          items={[%{label: "Orders", href: "/orders", current: true}]}
        >
          <p>Content</p>
        </C.app_shell>
        """
      end)

    refute LazyHTML.text(doc) =~ "Library"
    refute LazyHTML.text(doc) =~ "catalogue"
    refute LazyHTML.text(doc) =~ "Armature"
    refute present?(doc, ".armature-side-nav > .armature-eyebrow")
    refute present?(doc, ".armature-side-nav-brand")
    assert present?(doc, "#plain-shell-rail nav[aria-label='Main'] a[aria-current=page]")
  end

  describe "app_shell given a brand" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.app_shell
            id="named-shell"
            title="Ledger"
            subtitle="Finance"
            nav_label="Ledger sections"
            section_label="Accounts"
            heading="Overview"
            heading_id="named-overview"
            context="Ledger"
            items={[%{label: "Overview", href: "/"}]}
          >
            <p>Content</p>
          </C.app_shell>
          """
        end)

      %{doc: doc}
    end

    test "renders the section caption it is given", %{doc: doc} do
      assert text(doc, "#named-shell-rail > .armature-eyebrow") == "Accounts"
    end

    test "renders the brand title with its subtitle", %{doc: doc} do
      assert text(doc, "#named-shell-rail .armature-side-nav-brand span") == "Ledger"
      assert text(doc, "#named-shell-rail .armature-side-nav-brand small") == "Finance"
    end

    test "names the navigation as given", %{doc: doc} do
      assert present?(doc, "#named-shell-rail nav[aria-label='Ledger sections']")
    end
  end

  describe "grouped_nav" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.grouped_nav
            id="components"
            label="Components"
            event="choose"
            groups={[
              %{
                label: "Atoms",
                items: [
                  %{id: "button-link", label: "Button", patch: "/?node=button", current: true},
                  %{id: "link-link", label: "Link", href: "/?node=link", current: false}
                ]
              }
            ]}
          />
          """
        end)

      %{doc: doc}
    end

    test "marks the current link", %{doc: doc} do
      assert present?(doc, "nav[aria-label=Components] #button-link[aria-current=page]")
      refute present?(doc, "#link-link[aria-current]")
    end

    test "labels the native picker", %{doc: doc} do
      assert text(doc, "label[for=components-choice]") == "Components"
    end

    test "selects the current destination", %{doc: doc} do
      assert present?(
               doc,
               "#components-choice optgroup[label=Atoms] option[value='/?node=button'][selected]"
             )
    end

    test "the picker gets the select chevron wrapper", %{doc: doc} do
      assert present?(
               doc,
               "#components .armature-grouped-nav-picker .armature-select-wrap > select#components-choice"
             )
    end

    test "the picker form sends the choose event", %{doc: doc} do
      assert present?(doc, "form[phx-change=choose] select[name=destination]")
    end

    test "the picker is described by its hint", %{doc: doc} do
      assert present?(doc, "select[name=destination][aria-describedby=components-hint]")
      assert text(doc, "#components-hint") == "Choosing an option opens its page."
    end
  end

  describe "theme_switch" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <C.theme_switch id="theme" value="light" />
          """
        end)

      %{doc: doc}
    end

    test "groups the choices in a fieldset named by its legend", %{doc: doc} do
      assert text(doc, "#theme > fieldset > legend") == "Theme"
    end

    test "hides the legend visually by default", %{doc: doc} do
      assert present?(doc, "#theme legend.armature-sr-only")
    end

    test "offers auto, light and dark as radios named theme", %{doc: doc} do
      values =
        for {"input", attributes, _} <-
              doc |> LazyHTML.query("#theme input[type=radio][name=theme]") |> LazyHTML.to_tree(),
            do: :proplists.get_value("value", attributes)

      assert values == ["auto", "light", "dark"]
    end

    test "checks only the radio that matches value", %{doc: doc} do
      assert present?(doc, "#theme-light[checked]")
      refute present?(doc, "#theme-auto[checked], #theme-dark[checked]")
    end

    test "names each segment in words", %{doc: doc} do
      names = for value <- ~w(auto light dark), do: text(doc, "label:has(> #theme-#{value})")
      assert names == ["System", "Light", "Dark"]
    end

    test "gives each segment a tooltip matching its name", %{doc: doc} do
      assert attribute(doc, "label:has(> #theme-auto)", "title") == "System"
    end

    test "draws each icon as hidden decoration in the current colour", %{doc: doc} do
      assert doc
             |> LazyHTML.query("#theme .armature-icon[aria-hidden=true] > svg")
             |> Enum.count() ==
               3

      assert doc |> LazyHTML.query("#theme svg[stroke=currentColor]") |> Enum.count() == 3
    end

    test "checks auto when no value is given" do
      doc = document(fn assigns -> ~H|<C.theme_switch id="theme" />| end)
      assert present?(doc, "#theme-auto[checked]")
    end

    test "shows the legend when label_visible is set" do
      doc =
        document(fn assigns ->
          ~H|<C.theme_switch id="theme" label="Appearance" label_visible />|
        end)

      assert text(doc, "#theme legend:not(.armature-sr-only)") == "Appearance"
    end

    test "themes/0 lists the values theme_switch accepts" do
      value = Enum.find(C.__components__().theme_switch.attrs, &(&1.name == :value))
      assert C.themes() == Keyword.fetch!(value.opts, :values)
    end

    test "theme_attribute/1 omits the attribute for auto" do
      assert C.theme_attribute("auto") == nil
    end

    test "theme_attribute/1 names an explicit theme" do
      assert C.theme_attribute("dark") == "dark"
    end
  end

  defp slot_attrs(component, slot) do
    C.__components__()
    |> Map.fetch!(component)
    |> Map.fetch!(:slots)
    |> Enum.find(&(&1.name == slot))
    |> Map.fetch!(:attrs)
    |> Enum.map(&{&1.name, &1.type, &1.required})
  end

  defp declared_attrs(component, names) do
    for attr <- C.__components__() |> Map.fetch!(component) |> Map.fetch!(:attrs),
        attr.name in names,
        do: {attr.name, attr.type, attr.required, Keyword.get(attr.opts, :default)}
  end

  defp rest_include(component) do
    C.__components__()
    |> Map.fetch!(component)
    |> Map.fetch!(:attrs)
    |> Enum.find(&(&1.name == :rest))
    |> Map.fetch!(:opts)
    |> Keyword.fetch!(:include)
  end

  defp shell_document do
    document(fn assigns ->
      ~H"""
      <C.app_shell
        id="shell"
        home_patch="/index"
        title="Library"
        heading="Overview"
        heading_id="overview"
        eyebrow="Library / Overview"
        context="Library / Catalogue"
        items={[%{id: "overview-link", label: "Overview", href: "/", current: true}]}
      >
        <:footnote>Synthetic examples</:footnote>
        <:top_actions><C.theme_switch id="theme" value="dark" event="theme" /></:top_actions>
        <:heading_actions><C.status label="Ready" /></:heading_actions>
        <C.panel id="summary" heading="Summary">
          Content
          <:actions><C.button>Refresh</C.button></:actions>
        </C.panel>
      </C.app_shell>
      <C.side_nav
        id="separate-nav"
        title="Examples"
        label="Example sections"
        items={[%{label: "First", patch: "/first", current: false}]}
      />
      <C.top_bar context="Examples">
        <:actions><C.button>Action</C.button></:actions>
      </C.top_bar>
      <C.page_heading id="separate-heading" title="Examples" eyebrow="Library" />
      <C.eyebrow>Section</C.eyebrow>
      """
    end)
  end

  defp sortable_records_document(sort_by, direction) do
    document(
      fn assigns ->
        ~H"""
        <C.data_table
          id="records"
          rows={[%{id: "R-1", name: "Example", score: 12}, %{id: "R-2", name: "Other", score: 3}]}
          caption="Example records"
          sort_by={@sort_by}
          sort_direction={@direction}
          sort_event="order"
          select_event="choose"
          selected_id="R-1"
          inspector_id="details"
        >
          <:col :let={row} label="Name" sort_key="name" row_label>{row.name}</:col>
          <:col :let={row} label="Score" numeric sort_key="score">{row.score}</:col>
        </C.data_table>
        <C.inspector id="details" title="Record details">Supporting information</C.inspector>
        """
      end,
      %{direction: direction, sort_by: sort_by}
    )
  end

  defp pagination_document(page, pages, first, last, total) do
    document(&C.pagination/1, %{
      id: "pages",
      page: page,
      pages: pages,
      first: first,
      last: last,
      total: total,
      page_event: "page",
      page_size: 25,
      page_sizes: [10, 25, 50],
      size_event: "size"
    })
  end

  defp text(doc, selector),
    do: doc |> LazyHTML.query(selector) |> LazyHTML.text() |> String.trim()

  defp children(doc, selector) do
    [{_, _, children}] = doc |> LazyHTML.query(selector) |> LazyHTML.to_tree()
    Enum.reject(children, &(is_binary(&1) and String.trim(&1) == ""))
  end

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

  defp translated_form_field_document(params) do
    form =
      to_form(params, as: :sample, errors: [name: {"needs %{count} characters", [count: 2]}])

    translate = fn {message, options} ->
      String.replace(message, "%{count}", to_string(options[:count]))
    end

    document(
      fn assigns ->
        ~H"""
        <C.field field={@form[:name]} label="Name" hint="A hint" translate_error={@translate} />
        """
      end,
      %{form: form, translate: translate}
    )
  end

  defp checkbox_field_document(value) do
    document(
      fn assigns ->
        ~H"""
        <C.field field={@form[:accepted]} type="checkbox" label="Accept the terms" />
        """
      end,
      %{form: to_form(%{"accepted" => value}, as: :sample)}
    )
  end

  defp notice_document(tone, result) do
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
  end

  defp invalid_selectable_table_document(columns) do
    document(&C.data_table/1, %{
      id: "invalid",
      rows: [],
      caption: "Records",
      select_event: "choose",
      inspector_id: "details",
      col: columns
    })
  end

  defp plain_table_document(rows) do
    document(
      fn assigns ->
        ~H"""
        <C.data_table id="plain" rows={@rows} caption="Records" caption_hidden>
          <:col :let={row} label="Name" sort_key="name" row_label>{row.name}</:col>
        </C.data_table>
        """
      end,
      %{rows: rows}
    )
  end

  defp toolbar_search_document(query) do
    document(
      fn assigns ->
        ~H"""
        <C.table_toolbar id="search" search_event="filter" query={@query} total={1} />
        """
      end,
      %{query: query}
    )
  end

  defp density_document(density) do
    document(
      fn assigns ->
        ~H"""
        <C.data_table id="density" caption="Records" rows={[%{id: "R-001"}]} density={@density}>
          <:col :let={row} label="Identifier">{row.id}</:col>
        </C.data_table>
        """
      end,
      %{density: density}
    )
  end
end
