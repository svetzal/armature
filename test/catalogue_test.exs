defmodule Armature.CatalogueTest do
  use ExUnit.Case
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint Armature.CatalogueTest.Endpoint

  setup_all do
    Application.put_env(:armature, @endpoint,
      secret_key_base: String.duplicate("a", 64),
      live_view: [signing_salt: "catalogue"],
      server: false,
      pubsub_server: Armature.CatalogueTest.PubSub
    )

    start_supervised!({Phoenix.PubSub, name: Armature.CatalogueTest.PubSub})
    start_supervised!(@endpoint)
    :ok
  end

  test "shell level navigation, picker, skip target and history preserve the selected component" do
    {:ok, view, _} = live(build_conn(), "/ui?node=button")
    assert has_element?(view, "#armature-catalogue-rail nav[aria-label='Library sections']")
    assert has_element?(view, "#catalogue-level-atom[aria-current=page]")
    assert has_element?(view, "main[aria-labelledby=armature-catalogue-heading-button]")
    assert has_element?(view, "a.armature-skip-link[href='#armature-catalogue-heading-button']")
    assert has_element?(view, ".armature-page-heading .armature-eyebrow", "Library / Atoms")
    assert has_element?(view, "label[for=catalogue-components-choice]", "Components")
    refute has_element?(view, "#catalogue-components nav section[data-level=molecule]")

    view |> form("#catalogue-components-form", %{destination: "/ui?node=link"}) |> render_change()
    assert_patch(view, "/ui?node=link")
    assert has_element?(view, "#catalogue-node-link[aria-current=page]")

    assert has_element?(
             view,
             "#catalogue-components-choice option[value='/ui?node=link'][selected]"
           )

    render_patch(view, "/ui?node=button")
    assert has_element?(view, "#catalogue-node-button[aria-current=page]")
    render_patch(view, "/ui?node=link")
    assert has_element?(view, "#armature-catalogue-heading-link[phx-mounted]")
    render_change(view, "catalogue:choose", %{destination: "https://example.invalid/"})
    assert has_element?(view, "#catalogue-node-link[aria-current=page]")
    view |> element("#catalogue-level-organism") |> render_click()
    assert_patch(view, "/ui?level=organism")
    assert has_element?(view, "#catalogue-level-organism[aria-current=page]")
    assert has_element?(view, "#catalogue-components nav section[data-level=organism]")
    refute has_element?(view, "#catalogue-components nav section[data-level=atom]")
    view |> element(".armature-side-nav-brand a") |> render_click()
    assert_patch(view, "/ui")
    assert has_element?(view, "#armature-catalogue-heading-index")
  end

  test "full page examples have one outer main and isolated named previews with width choices" do
    {:ok, view, html} = live(build_conn(), "/ui?node=app_shell")
    assert LazyHTML.from_fragment(html) |> LazyHTML.query("main") |> Enum.count() == 1
    assert has_element?(view, "iframe[title='app_shell: app_shell in use'][srcdoc]")
    [frame] = html |> LazyHTML.from_fragment() |> LazyHTML.query("iframe") |> LazyHTML.to_tree()
    {"iframe", attributes, _children} = frame
    framed = attributes |> List.keyfind("srcdoc", 0) |> elem(1) |> LazyHTML.from_document()
    assert framed |> LazyHTML.query("main") |> Enum.count() == 1

    assert framed
           |> LazyHTML.query(".armature-app-shell > .armature-app-shell-grid")
           |> Enum.count() == 1

    assert LazyHTML.text(LazyHTML.query(framed, "style")) =~
             "@container armature-shell (width < 520px)"

    assert has_element?(view, "#catalogue-preview-width option[value='375']", "375px")
    view |> form("#catalogue-preview-form", %{width: "375"}) |> render_change()
    assert has_element?(view, "iframe[width='375']")
    assert has_element?(view, "#catalogue-preview-status[role=status]", "Preview width: 375px")
    doc = LazyHTML.from_fragment(render(view))
    assert doc |> LazyHTML.query("main") |> Enum.count() == 1
  end

  test "examples with wrapped headers or footers render in an isolated document" do
    {:ok, _view, html} = live(build_conn(), "/nested/ui?node=masthead")
    doc = LazyHTML.from_fragment(html)

    # The wrapped header and footer must not join the catalogue's own page.
    assert doc |> LazyHTML.query("main") |> Enum.count() == 1
    assert doc |> LazyHTML.query("main header, main footer") |> Enum.count() == 0

    [frame] = doc |> LazyHTML.query("iframe") |> LazyHTML.to_tree()
    {"iframe", attributes, _children} = frame
    framed = attributes |> List.keyfind("srcdoc", 0) |> elem(1) |> LazyHTML.from_document()
    assert framed |> LazyHTML.query(".example-frame > header") |> Enum.count() == 1
    assert framed |> LazyHTML.query(".example-frame > footer") |> Enum.count() == 1
  end

  test "grouped navigation sits inside the layout it collapses against" do
    {:ok, _view, html} = live(build_conn(), "/ui?node=button")
    doc = LazyHTML.from_fragment(html)

    assert doc
           |> LazyHTML.query(
             ".armature-app-shell-content .armature-grouped-nav > .armature-grouped-nav-picker"
           )
           |> Enum.count() == 1
  end

  test "consumer title is configurable and shell examples announce choices" do
    {:ok, view, _} = live(build_conn(), "/nested/ui?node=theme_switch")
    assert has_element?(view, ".armature-side-nav-brand", "Example library")
    view |> form("#example-theme", %{theme: "dark"}) |> render_change()
    assert has_element?(view, "#example-theme-choice option[value=dark][selected]")
    assert has_element?(view, "p[role=status]", "Selected theme: dark")
    render_patch(view, "/nested/ui?node=grouped_nav")
    view |> form("#example-grouped-form", %{destination: "#catalogue-used-by"}) |> render_change()
    assert has_element?(view, "p[role=status]", "Selected destination: #catalogue-used-by")
  end

  test "configured consumer stylesheet changes server contrast results" do
    {:ok, view, _html} = live(build_conn(), "/overrides?section=tokens")

    assert has_element?(
             view,
             "#catalogue-token-contrast tr[data-foreground='--armature-ink'] td[data-theme='light']",
             "1.00:1"
           )

    assert has_element?(
             view,
             "#catalogue-token-contrast tr[data-foreground='--armature-ink'] td[data-theme='light']",
             "Fail"
           )

    assert has_element?(
             view,
             "#catalogue-token-contrast tr[data-foreground='--armature-ink'] td[data-theme='explicit_light']",
             "Fail"
           )

    assert has_element?(
             view,
             "#catalogue-token-contrast tr[data-foreground='--armature-ink'] td[data-theme='dark']",
             "Pass"
           )
  end

  test "tokens precede atoms and show contract samples and both theme results" do
    {:ok, view, _html} = live(build_conn(), "/ui?section=tokens")
    assert has_element?(view, "nav > a:first-child#catalogue-tokens[aria-current='page']")
    assert has_element?(view, "#armature-catalogue-heading-tokens", "Tokens")

    assert has_element?(
             view,
             "#catalogue-token-statement",
             "Tokens give every component a shared language."
           )

    for {id, heading} <- [
          {"surfaces", "Surfaces and text"},
          {"accents", "Accents, focus and selection"},
          {"status", "Status tones"},
          {"rail", "Rail"},
          {"typography", "Typography"},
          {"space", "Space and rhythm"},
          {"shape", "Shape"},
          {"density", "Density and targets"},
          {"motion", "Motion"},
          {"contrast", "Contrast"}
        ] do
      assert has_element?(view, "#catalogue-token-#{id}.armature-panel h2", heading)
    end

    for group <- Enum.uniq(Enum.map(Armature.Tokens.all(), & &1.group)) do
      assert has_element?(view, "[data-token-group='#{group}']")
    end

    values = Armature.Tokens.Values.read([])

    for token <- Armature.Tokens.all() do
      selector = "#token-#{String.trim_leading(token.name, "--")}"
      assert has_element?(view, "#catalogue-token-reference #{selector} th", token.name)
      assert has_element?(view, "#{selector} td", token.role)

      for {context, _label} <- Armature.Tokens.Values.contexts() do
        assert has_element?(
                 view,
                 "#{selector} td[data-context='#{context}']",
                 values[context].values[token.name]
               )
      end
    end

    for {context, _label} <- Armature.Tokens.Values.contexts(), pair <- values[context].pairs do
      selector =
        "#catalogue-token-contrast tr" <>
          "[data-foreground='#{pair.foreground}'][data-background='#{pair.background}']"

      assert has_element?(view, selector <> " td", "#{pair.minimum}:1")
      expected_ratio = :erlang.float_to_binary(pair.ratio, decimals: 2) <> ":1"
      assert has_element?(view, selector <> " td[data-theme='#{context}']", expected_ratio)

      assert has_element?(
               view,
               selector <> " td[data-theme='#{context}']",
               if(pair.pass?, do: "Pass", else: "Fail")
             )
    end

    doc = LazyHTML.from_fragment(render(view))

    assert Enum.count(LazyHTML.query(doc, "#catalogue-token-reference tbody tr")) ==
             length(Armature.Tokens.all())

    assert Enum.count(LazyHTML.query(doc, "#catalogue-token-contrast table")) == 1

    assert Enum.count(LazyHTML.query(doc, "#catalogue-token-contrast tbody tr")) ==
             length(values.light.pairs)

    assert has_element?(view, "#catalogue-token-selection button[aria-pressed=true]")
    assert has_element?(view, "#catalogue-focus-sample")
    assert has_element?(view, "#catalogue-tabular-sample")
    assert has_element?(view, "#catalogue-density-compact[data-density=compact]")
    assert has_element?(view, "#catalogue-token-select.armature-select")
    assert has_element?(view, "#catalogue-token-search-search[type=search]")
    assert has_element?(view, "#catalogue-motion-demo .armature-token-motion-fast")

    view |> form("#catalogue-theme", %{theme: "dark"}) |> render_change()
    assert has_element?(view, "#armature-catalogue[data-armature-theme='dark']")
    view |> element("#catalogue-level-atom") |> render_click()
    view |> element("#catalogue-node-button") |> render_click()
    assert has_element?(view, "#catalogue-tokens")
    view |> element("#catalogue-tokens") |> render_click()
    assert has_element?(view, "#armature-catalogue-heading-tokens")
  end

  test "index groups components in level order and renders one heading" do
    {:ok, view, html} = live(build_conn(), "/ui")
    assert has_element?(view, "h1", "Component catalogue")
    assert LazyHTML.from_fragment(html) |> LazyHTML.query("h1") |> Enum.count() == 1

    levels =
      LazyHTML.from_fragment(html)
      |> LazyHTML.query("nav[aria-label='Components'] section")
      |> LazyHTML.attribute("data-level")

    assert levels == ~w(atom layout molecule organism template)

    for node <- Armature.UI.Registry.nodes() do
      assert has_element?(view, "#catalogue-node-#{node.id}[href='/ui?node=#{node.id}']")
    end
  end

  test "navigation follows both relationship directions and marks the current entry" do
    {:ok, view, _} = live(build_conn(), "/ui?node=field")
    assert has_element?(view, "#catalogue-node-field[aria-current='page']")
    assert has_element?(view, "#catalogue-uses a[href='/ui?node=input']")
    view |> element("#catalogue-uses a[href='/ui?node=input']") |> render_click()
    assert_patch(view, "/ui?node=input")
    assert has_element?(view, "#catalogue-used-by a[href='/ui?node=field']")
    assert has_element?(view, "#armature-catalogue-heading-input[tabindex='-1'][phx-mounted]")
    render_patch(view, "/ui?node=field")
    assert has_element?(view, "#catalogue-node-field[aria-current='page']")
    render_patch(view, "/ui?node=unknown")
    assert has_element?(view, "h1", "Component catalogue")
    refute has_element?(view, "nav[aria-label='Components'] [aria-current]")
  end

  test "every baseline node renders examples and usage notes" do
    {:ok, view, _} = live(build_conn(), "/ui")

    for node <- Armature.UI.Registry.nodes() do
      render_patch(view, "/ui?node=#{node.id}")
      assert has_element?(view, "#catalogue-examples article")
      assert has_element?(view, "#catalogue-usage")
      refute has_element?(view, "#catalogue-no-examples")
    end
  end

  test "missing examples are explained in words" do
    {:ok, view, _} = live(build_conn(), "/empty?node=button")

    assert has_element?(
             view,
             "#catalogue-no-examples",
             "No examples supplied for this component."
           )
  end

  test "theme control switches the container and rejects unknown themes" do
    {:ok, view, _} = live(build_conn(), "/ui")

    # Auto sets no attribute, so the consumer's own :root tokens apply.
    refute has_element?(view, "#armature-catalogue[data-armature-theme]")

    for theme <- ~w(dark light) do
      view |> form("#catalogue-theme", %{"theme" => theme}) |> render_change()
      assert has_element?(view, "#armature-catalogue[data-armature-theme='#{theme}']")
    end

    view |> form("#catalogue-theme", %{"theme" => "auto"}) |> render_change()
    refute has_element?(view, "#armature-catalogue[data-armature-theme]")

    render_change(view, "catalogue:theme", %{"theme" => "unknown"})
    refute has_element?(view, "#armature-catalogue[data-armature-theme]")
  end

  test "examples validate fields and keep action state while navigating" do
    {:ok, view, _} = live(build_conn(), "/ui?node=button")
    view |> element("#example-action") |> render_click()
    assert has_element?(view, "p[role=status]", "Activated 1 times.")
    render_patch(view, "/ui?node=field")
    view |> form("#sample-form", %{"sample" => %{"name" => ""}}) |> render_submit()
    assert has_element?(view, "#sample_name[aria-invalid=true]")
    refute has_element?(view, "#example-saved")
    view |> form("#sample-form", %{"sample" => %{"name" => "Sample"}}) |> render_change()
    refute has_element?(view, "#sample_name[aria-invalid=true]")
    view |> form("#sample-form", %{"sample" => %{"name" => "Sample"}}) |> render_submit()
    assert has_element?(view, "#example-saved[role=status]")
    render_patch(view, "/ui?node=button")
    assert has_element?(view, "p[role=status]", "Activated 1 times.")
  end

  test "record examples sort, page, search and retain selected details" do
    {:ok, view, _} = live(build_conn(), "/ui?node=table_inspector")
    view |> element("button[phx-value-key=score]") |> render_click()
    assert has_element?(view, "th[aria-sort=ascending]", "Score")
    view |> element("button[phx-value-key=score]") |> render_click()
    assert has_element?(view, "th[aria-sort=descending]", "Score")
    view |> element("button[aria-label='Next page']") |> render_click()
    assert has_element?(view, "#example-records-pagination-range", "26–50 of 200")

    view
    |> form("#example-records-pagination-size-form", %{"page_size" => "10"})
    |> render_change()

    assert has_element?(view, "#example-records-pagination-range", "1–10 of 200")
    view |> form("#example-records-toolbar-search-form", %{"query" => "R-001"}) |> render_change()
    assert has_element?(view, "#example-records-toolbar-count", "1 results")
    view |> element("#example-records-table-R-001") |> render_click()
    assert has_element?(view, "button[phx-value-id=R-001][aria-pressed=true]")
    assert has_element?(view, "#example-selected-record", "R-001")

    view
    |> form("#example-records-toolbar-search-form", %{"query" => "no match"})
    |> render_change()

    assert has_element?(view, "#example-selected-record", "R-001")
    assert has_element?(view, "p", "The selected record is outside the current results.")
    assert has_element?(view, "#example-records-pagination-range", "0–0 of 0")
    render_patch(view, "/ui?node=data_table")
    assert has_element?(view, "#example-selected-record", "R-001")
    render_click(view, "record_select", %{"id" => "unknown"})
    render_click(view, "record_sort", %{"key" => "unknown"})
    render_click(view, "record_page", %{"page" => "invalid"})
    render_click(view, "record_size", %{"page_size" => "0"})
    assert has_element?(view, "#example-selected-record", "R-001")
  end

  test "row labels announce selection and keep it across search and paging" do
    {:ok, view, _} = live(build_conn(), "/ui?node=table_inspector")
    view |> form("#example-records-toolbar-search-form", %{query: "R-173"}) |> render_change()
    assert has_element?(view, "#example-records-table-R-173 button", "Example 001")
    view |> element("#example-records-table-R-173 button") |> render_click()
    assert has_element?(view, "#example-records-selection", "Selected R-173, Example 001.")

    assert has_element?(
             view,
             "#example-records-table-R-173 button[aria-pressed=true][aria-controls=example-records-inspector]"
           )

    view |> form("#example-records-toolbar-search-form", %{query: ""}) |> render_change()
    view |> element("button[aria-label='Next page']") |> render_click()
    assert has_element?(view, "#example-records-selection", "Selected R-173, Example 001.")
    assert has_element?(view, "#example-selected-record", "R-173")
  end

  test "search clears through the named action and restores the result count" do
    {:ok, view, _} = live(build_conn(), "/ui?node=table_inspector")
    view |> form("#example-records-toolbar-search-form", %{"query" => "R-001"}) |> render_change()
    assert has_element?(view, "#example-records-toolbar-clear[aria-label='Clear search']")
    assert has_element?(view, "#example-records-table[data-density=compact]")
    view |> element("#example-records-toolbar-clear") |> render_click()
    assert has_element?(view, "#example-records-toolbar-search[value='']")
    assert has_element?(view, "#example-records-toolbar-count", "200 results")
    refute has_element?(view, "#example-records-toolbar-clear")
  end

  test "an aliased nested scope renders the consumer registry and extensions" do
    {:ok, view, _} = live(build_conn(), "/nested/ui?node=marker")

    assert has_element?(
             view,
             "#catalogue-node-marker[aria-current=page][href='/nested/ui?node=marker']"
           )

    assert has_element?(view, "#catalogue-node-button[href='/nested/ui?node=button']")
    assert has_element?(view, "#example-extension", "Example extension")
    assert has_element?(view, "#catalogue-usage", "A synthetic extension with a visible name.")
  end
end
