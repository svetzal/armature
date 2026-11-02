defmodule Armature.Components.TemplatesTest do
  use Armature.ComponentsCase, async: true
  alias Armature.Components.Atoms
  alias Armature.Components.Layouts
  alias Armature.Components.Molecules
  alias Armature.Components.Organisms
  alias Armature.Components.Templates

  describe "responsive composition" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Templates.app_shell
            id="responsive-shell"
            title="Library"
            heading="Overview"
            heading_id="responsive-heading"
            context="Library"
            items={[]}
          >
            <Organisms.grouped_nav id="responsive-nav" label="Components" event="choose" groups={[]} />
            <Layouts.grid id="responsive-panels">
              <Organisms.panel id="first-panel" heading="First">Content</Organisms.panel>
              <Organisms.panel id="second-panel" heading="Second">Content</Organisms.panel>
            </Layouts.grid>
          </Templates.app_shell>
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

  describe "table_inspector" do
    setup do
      doc =
        document(fn assigns ->
          ~H"""
          <Templates.table_inspector
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
            <:actions><Atoms.button>Export</Atoms.button></:actions>
            <:details><Molecules.record_header id="selected" title="Record R-1" /></:details>
          </Templates.table_inspector>
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

    test "passes search_label to the toolbar" do
      doc =
        document(fn assigns ->
          ~H"""
          <Templates.table_inspector
            id="browser"
            rows={[]}
            caption="Records"
            total={0}
            page={1}
            pages={1}
            first={0}
            last={0}
            search_event="search"
            sort_event="sort"
            page_event="page"
            select_event="select"
            search_label="Datensätze suchen"
          >
            <:col :let={row} label="Name" row_label>{row.name}</:col>
            <:details>Nothing selected</:details>
          </Templates.table_inspector>
          """
        end)

      assert text(doc, "label[for=browser-toolbar-search]") == "Datensätze suchen"
    end

    test "declares the same col slot attributes as data_table" do
      assert slot_attrs(:table_inspector, :col) == slot_attrs(:data_table, :col)
    end

    test "declares the paging attributes as pagination does" do
      paging =
        ~w(page pages first last total page_event page_size page_sizes size_event label previous_label next_label page_size_label)a

      assert declared_attrs(:table_inspector, paging) == declared_attrs(:pagination, paging)
    end
  end

  describe "app_shell" do
    setup do
      %{doc: shell_document()}
    end

    test "skip link targets the main heading", %{doc: doc} do
      assert text(doc, "#shell > a:first-child[href='#overview']") == "Skip to main content"
    end

    test "skip link reads a supplied skip_label" do
      doc =
        document(fn assigns ->
          ~H"""
          <Templates.app_shell
            id="shell"
            heading="Overview"
            heading_id="overview"
            context="Overview"
            items={[]}
            skip_label="Zum Inhalt springen"
          >
            Content
          </Templates.app_shell>
          """
        end)

      assert text(doc, "#shell > a:first-child") == "Zum Inhalt springen"
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

  test "an app shell forwards its mark to the side navigation brand" do
    doc =
      document(fn assigns ->
        ~H"""
        <Templates.app_shell
          id="marked-shell"
          title="Library"
          heading="Overview"
          heading_id="marked-overview"
          context="Library"
          items={[%{label: "Overview", href: "/"}]}
        >
          <:mark><svg id="shell-art" viewBox="0 0 2 5"><path d="M1 0 2 5H0Z" /></svg></:mark>
          <p>Content</p>
        </Templates.app_shell>
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
        <Templates.app_shell
          id="plain-shell"
          heading="Orders"
          heading_id="orders"
          context="Orders"
          items={[%{label: "Orders", href: "/orders", current: true}]}
        >
          <p>Content</p>
        </Templates.app_shell>
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
          <Templates.app_shell
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
          </Templates.app_shell>
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

  defp shell_document do
    document(fn assigns ->
      ~H"""
      <Templates.app_shell
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
        <:top_actions><Molecules.theme_switch id="theme" value="dark" event="theme" /></:top_actions>
        <:heading_actions><Atoms.status label="Ready" /></:heading_actions>
        <Organisms.panel id="summary" heading="Summary">
          Content
          <:actions><Atoms.button>Refresh</Atoms.button></:actions>
        </Organisms.panel>
      </Templates.app_shell>
      <Organisms.side_nav
        id="separate-nav"
        title="Examples"
        label="Example sections"
        items={[%{label: "First", patch: "/first", current: false}]}
      />
      <Organisms.top_bar context="Examples">
        <:actions><Atoms.button>Action</Atoms.button></:actions>
      </Organisms.top_bar>
      <Molecules.page_heading id="separate-heading" title="Examples" eyebrow="Library" />
      <Atoms.eyebrow>Section</Atoms.eyebrow>
      """
    end)
  end
end
