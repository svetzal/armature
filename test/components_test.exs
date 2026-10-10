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

  test "checkbox fields reflect boolean FormField values and submit false when unchecked" do
    for {value, checked?} <- [
          {true, true},
          {"true", true},
          {false, false},
          {"false", false},
          {nil, false}
        ] do
      doc =
        document(
          fn assigns ->
            ~H"""
            <C.field field={@form[:accepted]} type="checkbox" label="Accept the terms" />
            """
          end,
          %{form: to_form(%{"accepted" => value}, as: :sample)}
        )

      assert present?(doc, "input#sample_accepted[type=checkbox][value=true]")
      assert present?(doc, "input#sample_accepted[checked]") == checked?
      # The box comes before its label, together in one row.
      assert present?(doc, ".armature-check > input#sample_accepted + label[for=sample_accepted]")

      assert doc |> LazyHTML.query("label[for=sample_accepted]") |> LazyHTML.to_tree() |> length() ==
               1

      # The hidden fallback precedes the box, so a ticked box's later value wins.
      [hidden, box] =
        doc |> LazyHTML.query("input[name='sample[accepted]']") |> LazyHTML.to_tree()

      assert {"type", "hidden"} in elem(hidden, 1) and {"value", "false"} in elem(hidden, 1)
      assert {"type", "checkbox"} in elem(box, 1)
    end

    # What a browser sends for an unticked and a ticked box, through Plug's decoder.
    assert Plug.Conn.Query.decode("sample[accepted]=false") == %{
             "sample" => %{"accepted" => "false"}
           }

    assert Plug.Conn.Query.decode("sample[accepted]=false&sample[accepted]=true") ==
             %{"sample" => %{"accepted" => "true"}}
  end

  test "disabled checkbox fields submit nothing and an explicit checked wins" do
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

    assert present?(doc, "input[type=hidden][name='sample[accepted]'][disabled]")
    assert present?(doc, "input#sample_accepted[type=checkbox][disabled]")
    assert present?(doc, "input#forced[type=checkbox][checked]")
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

  test "data tables expose scoped sortable headings and named record selection" do
    for sort_by <- ~w(name score), direction <- ~w(asc desc) do
      doc =
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
              <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
              <:col :let={row} label="Score" numeric sort_key="score">{row.score}</:col>
            </C.data_table>
            <C.inspector id="details" title="Record details">Supporting information</C.inspector>
            """
          end,
          %{direction: direction, sort_by: sort_by}
        )

      # aria-sort belongs to the heading whose button sorts by `sort_by`, and
      # to no other heading.
      [inactive] = ~w(name score) -- [sort_by]
      assert present?(doc, "th[aria-sort] button[phx-value-key=#{sort_by}]")
      assert present?(doc, "th:not([aria-sort]) button[phx-value-key=#{inactive}]")
      refute present?(doc, "th[aria-sort] button[phx-value-key=#{inactive}]")

      # Unsorted sortable columns show a decorative hint; the sorted one shows its arrow.
      assert present?(
               doc,
               "button[phx-value-key=#{inactive}] .armature-sort-hint[aria-hidden=true]"
             )

      refute present?(doc, "th[aria-sort] .armature-sort-hint")

      assert text(doc, "table caption") == "Example records"

      assert present?(
               doc,
               "#records-scroll[tabindex='0'][role=region][aria-label='Example records']"
             )

      assert length(LazyHTML.to_tree(LazyHTML.query(doc, "th[scope=col]"))) == 3
      assert length(LazyHTML.to_tree(LazyHTML.query(doc, "th[aria-sort]"))) == 1

      assert attribute(doc, "th[aria-sort]", "aria-sort") ==
               if(direction == "asc", do: "ascending", else: "descending")

      assert present?(
               doc,
               "th button[type=button][phx-click=order][phx-value-key=name][aria-label='Sort by Name']"
             )

      assert present?(doc, "th.armature-numeric button[phx-value-key=score]")
      assert present?(doc, "td.armature-numeric")

      assert present?(
               doc,
               "button[phx-click=choose][phx-value-id=R-1][aria-label='Select R-1'][aria-pressed=true][aria-controls=details]"
             )

      assert present?(doc, "button[phx-value-id=R-2][aria-pressed=false]")
      assert text(doc, "#records-R-1 .armature-row-select") == "Selected"
      assert present?(doc, "aside#details[aria-labelledby=details-heading]")
      assert text(doc, "#details-heading") == "Record details"
      refute present?(doc, "aside[aria-live], aside[role=status]")
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

  test "tables without selection or sorting remain native and empty results use words" do
    for rows <- [[], [%{id: "R-1", name: "Example"}]] do
      doc =
        document(
          fn assigns ->
            ~H"""
            <C.data_table id="plain" rows={@rows} caption="Records" caption_hidden>
              <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
            </C.data_table>
            """
          end,
          %{rows: rows}
        )

      refute present?(doc, "button, th[aria-sort]")

      if rows == [] do
        refute present?(doc, "table")
        assert text(doc, "#plain-empty") == "No records to display."
      else
        assert present?(doc, "caption.armature-sr-only")
        assert present?(doc, "th[scope=col]")
      end
    end
  end

  test "toolbar labels search and announces the count with caller actions" do
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

    assert text(doc, "label[for=tools-search]") == "Find records"

    assert present?(
             doc,
             "form#tools-search-form[phx-change=search] input#tools-search[type=search][name=query][value=Example]"
           )

    assert text(doc, "#tools-count[role=status][aria-live=polite][aria-atomic=true]") ==
             "200 results"

    assert text(doc, ".armature-toolbar-actions button") == "Export"
  end

  test "pagination names controls, disables boundaries and announces ranges" do
    for {page, pages, first, last, total} <- [
          {1, 80, 1, 25, 2000},
          {2, 80, 26, 50, 2000},
          {80, 80, 1976, 2000, 2000},
          {1, 1, 0, 0, 0}
        ] do
      doc =
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

      assert present?(doc, "nav[aria-label='Table pages']")

      assert present?(
               doc,
               "button[aria-label='Previous page'][phx-click=page][phx-value-page='#{max(1, page - 1)}']"
             )

      assert present?(
               doc,
               "button[aria-label='Next page'][phx-value-page='#{min(pages, page + 1)}']"
             )

      assert present?(doc, "button[aria-label='Previous page'][disabled]") == (page == 1)
      assert present?(doc, "button[aria-label='Next page'][disabled]") == (page == pages)

      expected =
        "#{first |> Integer.to_string() |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")}–#{last |> Integer.to_string() |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")} of #{total |> Integer.to_string() |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")}"

      assert text(doc, "#pages-range[role=status][aria-live=polite][aria-atomic=true]") ==
               expected

      assert text(doc, "label[for=pages-size]") == "Records per page"

      assert present?(
               doc,
               "form[phx-change=size] select#pages-size[name=page_size] option[value='25'][selected]"
             )
    end

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

  test "record headers expose the heading, context, status and actions" do
    doc =
      document(fn assigns ->
        ~H"""
        <C.record_header id="record" title="Record R-1" context="Example collection" status="Ready">
          <:actions><C.button>Update</C.button></:actions>
        </C.record_header>
        """
      end)

    assert text(doc, "header#record h2#record-heading") == "Record R-1"
    assert text(doc, "header p") == "Example collection"
    assert text(doc, "header .armature-status") == "Ready"
    assert text(doc, "header button") == "Update"
    doc = document(&C.record_header/1, %{id: "minimal", title: "Record"})
    refute present?(doc, "p, .armature-status, button")
  end

  test "table inspector composes the workflow and announces selection without focusing" do
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
          <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
          <:actions><C.button>Export</C.button></:actions>
          <:details><C.record_header id="selected" title="Record R-1" /></:details>
        </C.table_inspector>
        """
      end)

    assert present?(doc, "#browser .armature-split #browser-table")
    assert present?(doc, "#browser-toolbar input[type=search]")
    assert present?(doc, "#browser-pagination nav, nav#browser-pagination")
    assert present?(doc, "button[aria-controls=browser-inspector][aria-pressed=true]")
    assert present?(doc, "a[href='#browser-inspector']")

    assert text(doc, "#browser-selection[role=status][aria-live=polite][aria-atomic=true]") ==
             "Selected R-1"

    assert present?(
             doc,
             "aside#browser-inspector[tabindex='-1'][aria-labelledby=browser-inspector-heading] h2"
           )

    refute present?(doc, "[autofocus], aside[aria-live]")
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

  test "search clear is named and sends an empty query, with a decorative search icon" do
    for query <- ["", "Example"] do
      doc =
        document(
          fn assigns ->
            ~H"""
            <C.table_toolbar id="search" search_event="filter" query={@query} total={1} />
            """
          end,
          %{query: query}
        )

      assert present?(doc, ".armature-search > .armature-icon[aria-hidden=true]")

      assert present?(
               doc,
               "#search-clear[aria-label='Clear search'][phx-click=filter][phx-value-query='']"
             ) == (query != "")
    end
  end

  test "table density defaults to default and accepts compact" do
    for density <- ~w(default compact) do
      doc =
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

      assert present?(doc, "table#density[data-density=#{density}]")
      assert text(doc, "#density td") == "R-001"
    end
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
