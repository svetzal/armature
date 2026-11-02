defmodule Armature.Components.MoleculesTest do
  use Armature.ComponentsCase, async: true
  alias Armature.Components.Atoms
  alias Armature.Components.Molecules

  describe "field with hint and errors" do
    setup do
      docs =
        for type <- ~w(text select textarea), into: %{} do
          doc =
            document(
              fn assigns ->
                ~H"""
                <p id="external">Supporting text</p>
                <Molecules.field
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
          <Molecules.field id="valid" name="valid" label="Valid" aria-invalid="true" />
          <Molecules.field id="hinted" name="hinted" label="Hinted" hint="A hint" />
          <Molecules.field id="errored" name="errored" label="Errored" errors={["Required"]} />
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
            <Molecules.field field={@form[:name]} label="Name" />
            <Molecules.field field={@form[:name]} id="override" name="other" value="Second" label="Other" />
            <Molecules.field
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
            <Molecules.field field={@form[:accepted]} type="checkbox" label="Locked" disabled />
            <Molecules.field
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
      render_component(&Molecules.field/1, label: "Name", name: "name")
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
        <Molecules.notice id="guidance">Supporting information</Molecules.notice>
        """
      end)

    refute present?(doc, ".armature-notice-title, .armature-notice-actions")
    assert text(doc, "#guidance") == "Supporting information"
  end

  describe "table_toolbar" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Molecules.table_toolbar
            id="tools"
            search_label="Find records"
            search_event="search"
            query="Example"
            total={200}
          >
            <:actions><Atoms.button>Export</Atoms.button></:actions>
          </Molecules.table_toolbar>
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

    test "names the clear button with a supplied clear_label" do
      doc =
        document(fn assigns ->
          ~H"""
          <Molecules.table_toolbar
            id="tools"
            search_event="search"
            query="Example"
            total={2}
            clear_label="Suche leeren"
          />
          """
        end)

      assert present?(doc, "#tools-clear[aria-label='Suche leeren']")
    end

    test "formats the count with a supplied count_label" do
      doc =
        document(
          fn assigns ->
            ~H"""
            <Molecules.table_toolbar
              id="tools"
              search_event="search"
              total={1200}
              count_label={@count_label}
            />
            """
          end,
          %{count_label: fn total -> "Ergebnisse: #{total}" end}
        )

      assert text(doc, "#tools-count") == "Ergebnisse: 1200"
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
      assert present?(
               pagination_document(1, 80, 1, 25, 2000),
               "nav#pages[aria-label='Table pages']"
             )
    end

    test "previous sends the preceding page number" do
      doc = pagination_document(2, 80, 26, 50, 2000)

      assert present?(
               doc,
               "button#pages-previous[phx-click=page][phx-value-page='1']"
             )
    end

    test "next sends the following page number" do
      doc = pagination_document(2, 80, 26, 50, 2000)

      assert present?(doc, "button#pages-next[phx-click=page][phx-value-page='3']")
    end

    test "disables previous on the first page" do
      for {page, pages, first, last, total, previous_disabled?, _next_disabled?} <-
            @page_boundaries do
        doc = pagination_document(page, pages, first, last, total)

        assert present?(doc, "button#pages-previous[disabled]") ==
                 previous_disabled?
      end
    end

    test "disables next on the last page" do
      for {page, pages, first, last, total, _previous_disabled?, next_disabled?} <-
            @page_boundaries do
        doc = pagination_document(page, pages, first, last, total)
        assert present?(doc, "button#pages-next[disabled]") == next_disabled?
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

    test "the page buttons are named by their visible text" do
      doc = pagination_document(2, 80, 26, 50, 2000)
      assert text(doc, "#pages-previous:not([aria-label])") == "Previous"
      assert text(doc, "#pages-next:not([aria-label])") == "Next"
    end

    test "renders caller-supplied labels" do
      doc =
        pagination_document(2, 80, 26, 50, 2000, %{
          label: "Seiten",
          previous_label: "Zurück",
          next_label: "Weiter",
          page_size_label: "Einträge pro Seite"
        })

      assert present?(doc, "nav#pages[aria-label=Seiten]")
      assert text(doc, "#pages-previous") == "Zurück"
      assert text(doc, "#pages-next") == "Weiter"
      assert text(doc, "label[for=pages-size]") == "Einträge pro Seite"
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
        document(&Molecules.pagination/1, %{
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
          <Molecules.record_header
            id="record"
            title="Record R-1"
            context="Example collection"
            status="Ready"
          >
            <:actions><Atoms.button>Update</Atoms.button></:actions>
          </Molecules.record_header>
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
      doc = document(&Molecules.record_header/1, %{id: "minimal", title: "Record"})
      refute present?(doc, "p, .armature-status, button")
    end
  end

  describe "field forwarding" do
    test "a textarea field forwards wrap" do
      doc =
        document(fn assigns ->
          ~H|<Molecules.field id="notes" name="notes" label="Notes" type="textarea" wrap="off" />|
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
        <Molecules.facts>
          <:fact label="Identifier">R-001</:fact>
          <:fact label="Score">42</:fact>
        </Molecules.facts>
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

  describe "theme_switch" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Molecules.theme_switch id="theme" value="light" />
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
      doc = document(fn assigns -> ~H|<Molecules.theme_switch id="theme" />| end)
      assert present?(doc, "#theme-auto[checked]")
    end

    test "shows the legend when label_visible is set" do
      doc =
        document(fn assigns ->
          ~H|<Molecules.theme_switch id="theme" label="Appearance" label_visible />|
        end)

      assert text(doc, "#theme legend:not(.armature-sr-only)") == "Appearance"
    end

    test "themes/0 lists the values theme_switch accepts" do
      value = Enum.find(Molecules.__components__().theme_switch.attrs, &(&1.name == :value))
      assert Armature.Components.themes() == Keyword.fetch!(value.opts, :values)
    end

    test "theme_attribute/1 omits the attribute for auto" do
      assert Armature.Components.theme_attribute("auto") == nil
    end

    test "theme_attribute/1 names an explicit theme" do
      assert Armature.Components.theme_attribute("dark") == "dark"
    end
  end

  defp pagination_document(page, pages, first, last, total, labels \\ %{}) do
    document(
      &Molecules.pagination/1,
      Map.merge(
        %{
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
        },
        labels
      )
    )
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
        <Molecules.field field={@form[:name]} label="Name" hint="A hint" translate_error={@translate} />
        """
      end,
      %{form: form, translate: translate}
    )
  end

  defp checkbox_field_document(value) do
    document(
      fn assigns ->
        ~H"""
        <Molecules.field field={@form[:accepted]} type="checkbox" label="Accept the terms" />
        """
      end,
      %{form: to_form(%{"accepted" => value}, as: :sample)}
    )
  end

  defp notice_document(tone, result) do
    document(
      fn assigns ->
        ~H"""
        <Molecules.notice id="feedback" tone={@tone} result={@result} title="Outcome">
          Explained in words
          <:actions><Atoms.button id="continue">Continue</Atoms.button></:actions>
        </Molecules.notice>
        """
      end,
      %{tone: tone, result: result}
    )
  end

  defp toolbar_search_document(query) do
    document(
      fn assigns ->
        ~H"""
        <Molecules.table_toolbar id="search" search_event="filter" query={@query} total={1} />
        """
      end,
      %{query: query}
    )
  end

  describe "icon_button" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Molecules.icon_button id="add" icon="plus" label="Add record" phx-click="add" />
          <Molecules.icon_button id="show" icon="eye" label="Show hidden" pressed variant="primary" />
          <Molecules.icon_button id="hide" icon="eye-off" label="Hide hidden" pressed={false} disabled />
          <Molecules.icon_button id="own" label="Own glyph"><svg><path d="M0 0" /></svg></Molecules.icon_button>
          """
        end)

      %{doc: doc}
    end

    test "renders the native button atom with type button", %{doc: doc} do
      assert present?(doc, "button#add.armature-button[type=button]")
    end

    test "is named by its label in words", %{doc: doc} do
      assert text(doc, "#add .armature-sr-only") == "Add record"
    end

    test "offers its label as the native title", %{doc: doc} do
      assert attribute(doc, "#add", "title") == "Add record"
    end

    test "shows its named glyph as hidden decoration", %{doc: doc} do
      assert present?(doc, "#add > .armature-icon[aria-hidden=true] > svg > path")
    end

    test "shows a consumer glyph from its slot", %{doc: doc} do
      assert present?(doc, "#own > .armature-icon[aria-hidden=true] > svg > path[d='M0 0']")
    end

    test "defaults to the secondary variant", %{doc: doc} do
      assert present?(doc, "#add.armature-button-secondary")
    end

    test "takes the primary variant", %{doc: doc} do
      assert present?(doc, "#show.armature-button-primary")
    end

    test "has no pressed state as an ordinary action", %{doc: doc} do
      refute present?(doc, "#add[aria-pressed]")
    end

    test "exposes a pressed toggle", %{doc: doc} do
      assert attribute(doc, "#show", "aria-pressed") == "true"
    end

    test "exposes an unpressed toggle", %{doc: doc} do
      assert attribute(doc, "#hide", "aria-pressed") == "false"
    end

    test "renders disabled only when asked", %{doc: doc} do
      assert present?(doc, "#hide[disabled]")
      refute present?(doc, "#add[disabled]")
    end

    test "forwards rest attributes such as phx-click", %{doc: doc} do
      assert present?(doc, "#add[phx-click=add]")
    end

    test "marks itself for the square icon button styles", %{doc: doc} do
      assert present?(doc, "#add[data-armature-icon-button]")
    end
  end

  test "an icon button cannot render without a label" do
    assert_raise KeyError, fn -> document(&Molecules.icon_button/1, %{icon: "plus"}) end
  end

  test "an icon button needs an icon name or an inline SVG" do
    assert_raise ArgumentError, ~r/needs an icon name or an inline SVG/, fn ->
      document(&Molecules.icon_button/1, %{label: "Add"})
    end
  end

  test "an icon button refuses both an icon name and an inline SVG" do
    assert_raise ArgumentError, ~r/not both/, fn ->
      document(fn assigns ->
        ~H|<Molecules.icon_button icon="x" label="Close"><svg /></Molecules.icon_button>|
      end)
    end
  end

  describe "toolbar" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Molecules.toolbar id="tools" label="Record actions">
            <:group>
              <Molecules.icon_button id="add" icon="plus" label="Add" />
              <Molecules.icon_button id="edit" icon="pencil" label="Edit" disabled />
            </:group>
            <:group label="View">
              <Molecules.icon_button id="show" icon="eye" label="Show hidden" pressed={false} />
            </:group>
            <:group><Atoms.button id="more" variant="secondary">More</Atoms.button></:group>
          </Molecules.toolbar>
          <Molecules.toolbar id="column" label="Arrangement" orientation="vertical">
            <:group><Atoms.button id="up">Move up</Atoms.button></:group>
            <:group><Atoms.button id="down">Move down</Atoms.button></:group>
          </Molecules.toolbar>
          """
        end)

      %{doc: doc}
    end

    test "is a toolbar named by its label", %{doc: doc} do
      assert attribute(doc, "#tools[role=toolbar]", "aria-label") == "Record actions"
    end

    test "is horizontal by default", %{doc: doc} do
      assert attribute(doc, "#tools", "aria-orientation") == "horizontal"
    end

    test "takes a vertical orientation", %{doc: doc} do
      assert attribute(doc, "#column", "aria-orientation") == "vertical"
    end

    test "separates each group from the next", %{doc: doc} do
      assert doc |> LazyHTML.query("#tools > [role=separator]") |> Enum.count() == 2
    end

    test "places separators only between groups", %{doc: doc} do
      refute present?(
               doc,
               "#tools > [role=separator]:first-child, #tools > [role=separator]:last-child"
             )
    end

    test "orients separators across a horizontal toolbar", %{doc: doc} do
      assert attribute(doc, "#tools > [role=separator]:nth-child(2)", "aria-orientation") ==
               "vertical"
    end

    test "orients separators across a vertical toolbar", %{doc: doc} do
      assert attribute(doc, "#column > [role=separator]", "aria-orientation") == "horizontal"
    end

    test "names a labelled group", %{doc: doc} do
      assert attribute(doc, "#tools > [role=group]", "aria-label") == "View"
    end

    test "leaves an unlabelled group without a role", %{doc: doc} do
      assert doc |> LazyHTML.query("#tools > [role=group]") |> Enum.count() == 1
    end

    test "renders the caller's controls in order", %{doc: doc} do
      ids =
        for {"button", attributes, _} <-
              doc |> LazyHTML.query("#tools button") |> LazyHTML.to_tree(),
            do: :proplists.get_value("id", attributes)

      assert ids == ~w(add edit show more)
    end

    test "attaches the roving tabindex hook", %{doc: doc} do
      assert present?(doc, "#tools[phx-hook=ArmatureToolbar]")
    end

    test "leaves every control in the tab order without the hook", %{doc: doc} do
      refute present?(doc, "#tools [tabindex]")
    end
  end

  test "the toolbar hook ships in the Hex package under the name the markup uses" do
    script = File.read!(Path.expand("../../priv/static/armature-toolbar.js", __DIR__))
    assert "priv" in Mix.Project.config()[:package][:files]
    assert script =~ "export default ArmatureToolbar;"
  end
end
