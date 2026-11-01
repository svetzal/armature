defmodule Armature.Components.OrganismsTest do
  use Armature.ComponentsCase, async: true
  alias Armature.Components.Atoms
  alias Armature.Components.Organisms

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
          <Organisms.data_table
            id="actions"
            rows={[%{id: "R-1"}]}
            caption="Records"
            select_event="choose"
            inspector_id="details"
          >
            <:col :let={row} label="Identifier" row_label>{row.id}</:col>
            <:col label="Actions" interactive><Atoms.link href="/record">Open</Atoms.link></:col>
          </Organisms.data_table>
          """
        end)
      end
    end
  end

  test "tables without selection render rows that have no identifier" do
    doc =
      document(fn assigns ->
        ~H"""
        <Organisms.data_table
          id="totals"
          rows={[%{name: "First", total: 3}, %{name: "Second", total: 5}, [name: "Third", total: 8]]}
          caption="Totals"
        >
          <:col :let={row} label="Name">{row[:name]}</:col>
          <:col :let={row} label="Total" numeric>{row[:total]}</:col>
        </Organisms.data_table>
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
          <Organisms.data_table id="by-id" rows={[%{id: "R-1"}]} caption="Records">
            <:col :let={row} label="Identifier">{row.id}</:col>
          </Organisms.data_table>
          <Organisms.data_table id="by-key" rows={[%{key: "K-1"}]} row_id={& &1.key} caption="Records">
            <:col :let={row} label="Key">{row.key}</:col>
          </Organisms.data_table>
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
        <Organisms.data_table
          id="unidentified"
          rows={[%{name: "First"}]}
          caption="Records"
          select_event="choose"
          inspector_id="details"
        >
          <:col :let={row} label="Name" row_label>{row.name}</:col>
        </Organisms.data_table>
        """
      end)
    end
  end

  test "selection requires an inspector destination" do
    assert_raise ArgumentError, "selection requires an existing inspector_id", fn ->
      document(&Organisms.data_table/1, %{
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

  describe "side_nav given a mark" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Organisms.side_nav id="linked-mark" title="Library" home_patch="/index" items={[]}>
            <:mark><svg id="linked-art" viewBox="0 0 2 5"><path d="M1 0 2 5H0Z" /></svg></:mark>
          </Organisms.side_nav>
          <Organisms.side_nav id="plain-mark" title="Library" items={[]}>
            <:mark><svg id="plain-art" viewBox="0 0 2 5"><path d="M1 0 2 5H0Z" /></svg></:mark>
          </Organisms.side_nav>
          <Organisms.side_nav id="untitled-mark" subtitle="Examples" items={[]}>
            <:mark><svg id="untitled-art" viewBox="0 0 2 5"><path d="M1 0 2 5H0Z" /></svg></:mark>
          </Organisms.side_nav>
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

  describe "grouped_nav" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Organisms.grouped_nav
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

  defp sortable_records_document(sort_by, direction) do
    document(
      fn assigns ->
        ~H"""
        <Organisms.data_table
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
        </Organisms.data_table>
        <Organisms.inspector id="details" title="Record details">
          Supporting information
        </Organisms.inspector>
        """
      end,
      %{direction: direction, sort_by: sort_by}
    )
  end

  defp invalid_selectable_table_document(columns) do
    document(&Organisms.data_table/1, %{
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
        <Organisms.data_table id="plain" rows={@rows} caption="Records" caption_hidden>
          <:col :let={row} label="Name" sort_key="name" row_label>{row.name}</:col>
        </Organisms.data_table>
        """
      end,
      %{rows: rows}
    )
  end

  defp density_document(density) do
    document(
      fn assigns ->
        ~H"""
        <Organisms.data_table id="density" caption="Records" rows={[%{id: "R-001"}]} density={@density}>
          <:col :let={row} label="Identifier">{row.id}</:col>
        </Organisms.data_table>
        """
      end,
      %{density: density}
    )
  end
end
