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

  describe "catalogue shell" do
    setup do
      {:ok, view, _} = live(build_conn(), "/ui?node=button")
      %{view: view}
    end

    test "rail renders the library sections nav", %{view: view} do
      assert has_element?(view, "#armature-catalogue-rail nav[aria-label='Library sections']")
    end

    test "rail renders the library eyebrow", %{view: view} do
      assert has_element?(view, "#armature-catalogue-rail > .armature-eyebrow", "Library")
    end

    test "rail renders the brand caption", %{view: view} do
      assert has_element?(
               view,
               "#armature-catalogue-rail .armature-side-nav-brand small",
               "catalogue"
             )
    end

    test "current level is marked", %{view: view} do
      assert has_element?(view, "#catalogue-level-atom[aria-current=page]")
    end

    test "main is labelled by the node heading", %{view: view} do
      assert has_element?(view, "main[aria-labelledby=armature-catalogue-heading-button]")
    end

    test "skip link targets the node heading", %{view: view} do
      assert has_element?(view, "a.armature-skip-link[href='#armature-catalogue-heading-button']")
    end

    test "page heading eyebrow shows the level path", %{view: view} do
      assert has_element?(view, ".armature-page-heading .armature-eyebrow", "Library / Atoms")
    end

    test "components picker is labelled", %{view: view} do
      assert has_element?(view, "label[for=catalogue-components-choice]", "Components")
    end

    test "components picker lists only the current level", %{view: view} do
      refute has_element?(view, "#catalogue-components nav section[data-level=molecule]")
    end

    test "choosing a destination patches to it", %{view: view} do
      choose_destination(view, "/ui?node=link")
      assert_patch(view, "/ui?node=link")
      assert has_element?(view, "#catalogue-node-link[aria-current=page]")
    end

    test "choosing a destination selects it in the picker", %{view: view} do
      choose_destination(view, "/ui?node=link")

      assert has_element?(
               view,
               "#catalogue-components-choice option[value='/ui?node=link'][selected]"
             )
    end

    test "patching between nodes moves aria-current", %{view: view} do
      render_patch(view, "/ui?node=link")
      render_patch(view, "/ui?node=button")
      assert has_element?(view, "#catalogue-node-button[aria-current=page]")
    end

    test "patching to a node remounts its heading", %{view: view} do
      render_patch(view, "/ui?node=link")
      render_patch(view, "/ui?node=button")
      render_patch(view, "/ui?node=link")
      assert has_element?(view, "#armature-catalogue-heading-link[phx-mounted]")
    end

    test "picker ignores destinations outside the catalogue", %{view: view} do
      render_patch(view, "/ui?node=link")
      render_change(view, "catalogue:choose", %{destination: "https://example.invalid/"})
      assert has_element?(view, "#catalogue-node-link[aria-current=page]")
    end

    test "choosing a level filters the component list to that level", %{view: view} do
      view |> element("#catalogue-level-organism") |> render_click()
      assert_patch(view, "/ui?level=organism")
      assert has_element?(view, "#catalogue-level-organism[aria-current=page]")
      assert has_element?(view, "#catalogue-components nav section[data-level=organism]")
      refute has_element?(view, "#catalogue-components nav section[data-level=atom]")
    end

    test "brand link returns to the index", %{view: view} do
      view |> element(".armature-side-nav-brand a") |> render_click()
      assert_patch(view, "/ui")
      assert has_element?(view, "#armature-catalogue-heading-index")
    end
  end

  describe "full page examples" do
    setup do
      {:ok, view, html} = live(build_conn(), "/ui?node=app_shell")
      [frame] = html |> LazyHTML.from_fragment() |> LazyHTML.query("iframe") |> LazyHTML.to_tree()
      {"iframe", attributes, _children} = frame
      framed = attributes |> List.keyfind("srcdoc", 0) |> elem(1) |> LazyHTML.from_document()
      %{view: view, html: html, framed: framed}
    end

    test "the catalogue page has one main landmark", %{html: html} do
      assert LazyHTML.from_fragment(html) |> LazyHTML.query("main") |> Enum.count() == 1
    end

    test "the preview iframe is titled after the example", %{view: view} do
      assert has_element?(view, "iframe[title='app_shell: app_shell in use'][srcdoc]")
    end

    test "the framed document has one main", %{framed: framed} do
      assert framed |> LazyHTML.query("main") |> Enum.count() == 1
    end

    test "the framed document renders the shell grid", %{framed: framed} do
      assert framed
             |> LazyHTML.query(".armature-app-shell > .armature-app-shell-grid")
             |> Enum.count() == 1
    end

    test "the framed stylesheet carries the shell container query", %{framed: framed} do
      assert LazyHTML.text(LazyHTML.query(framed, "style")) =~
               "@container armature-shell (width < 520px)"
    end

    test "the width picker offers a 375px choice", %{view: view} do
      assert has_element?(view, "#catalogue-preview-width option[value='375']", "375px")
    end

    test "choosing a width resizes the iframe", %{view: view} do
      choose_width(view, "375")
      assert has_element?(view, "iframe[width='375']")
    end

    test "choosing a width announces the new width", %{view: view} do
      choose_width(view, "375")
      assert has_element?(view, "#catalogue-preview-status[role=status]", "Preview width: 375px")
    end

    test "resizing keeps a single main on the page", %{view: view} do
      choose_width(view, "375")
      doc = LazyHTML.from_fragment(render(view))
      assert doc |> LazyHTML.query("main") |> Enum.count() == 1
    end
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

  test "consumer title is configurable" do
    {:ok, view, _} = live(build_conn(), "/nested/ui?node=theme_switch")
    assert has_element?(view, ".armature-side-nav-brand", "Example library")
  end

  test "theme switch example announces the chosen theme" do
    {:ok, view, _} = live(build_conn(), "/nested/ui?node=theme_switch")
    view |> form("#example-theme", %{theme: "dark"}) |> render_change()
    assert has_element?(view, "#example-theme-dark[checked]")
    assert has_element?(view, "p[role=status]", "Selected theme: dark")
  end

  test "grouped nav example announces the chosen destination" do
    {:ok, view, _} = live(build_conn(), "/nested/ui?node=grouped_nav")
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

  describe "tokens page" do
    setup do
      {:ok, view, _html} = live(build_conn(), "/ui?section=tokens")
      %{view: view, values: Armature.Tokens.Values.read([])}
    end

    test "tokens link is first in the section nav", %{view: view} do
      assert has_element?(view, "nav > a:first-child#catalogue-tokens")
    end

    test "tokens link is marked current", %{view: view} do
      assert has_element?(view, "#catalogue-tokens[aria-current='page']")
    end

    test "tokens page is headed Tokens", %{view: view} do
      assert has_element?(view, "#armature-catalogue-heading-tokens", "Tokens")
    end

    test "renders the token statement", %{view: view} do
      assert has_element?(
               view,
               "#catalogue-token-statement",
               "Tokens give every component a shared language."
             )
    end

    test "renders a heading for every themed panel", %{view: view} do
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
    end

    test "reference table names every token", %{view: view} do
      for token <- Armature.Tokens.all() do
        assert has_element?(view, "#catalogue-token-reference #{token_row(token)} th", token.name)
      end
    end

    test "reference table states every token role", %{view: view} do
      for token <- Armature.Tokens.all() do
        assert has_element?(view, "#{token_row(token)} td", token.role)
      end
    end

    test "reference table gives every token value per context", %{view: view, values: values} do
      for token <- Armature.Tokens.all(),
          {context, _label} <- Armature.Tokens.Values.contexts() do
        assert has_element?(
                 view,
                 "#{token_row(token)} td[data-context='#{context}']",
                 values[context].values[token.name]
               )
      end
    end

    test "contrast table reports the minimum ratio per pair", %{view: view, values: values} do
      for {context, _label} <- Armature.Tokens.Values.contexts(), pair <- values[context].pairs do
        assert has_element?(view, contrast_row(pair) <> " td", "#{pair.minimum}:1")
      end
    end

    test "contrast table reports the measured ratio per theme", %{view: view, values: values} do
      for {context, _label} <- Armature.Tokens.Values.contexts(), pair <- values[context].pairs do
        expected_ratio = :erlang.float_to_binary(pair.ratio, decimals: 2) <> ":1"

        assert has_element?(
                 view,
                 contrast_row(pair) <> " td[data-theme='#{context}']",
                 expected_ratio
               )
      end
    end

    test "contrast table reports the verdict per theme", %{view: view, values: values} do
      for {context, _label} <- Armature.Tokens.Values.contexts(), pair <- values[context].pairs do
        assert has_element?(
                 view,
                 contrast_row(pair) <> " td[data-theme='#{context}']",
                 if(pair.pass?, do: "Pass", else: "Fail")
               )
      end
    end

    test "reference table has one row per token", %{view: view} do
      doc = LazyHTML.from_fragment(render(view))

      assert Enum.count(LazyHTML.query(doc, "#catalogue-token-reference tbody tr")) ==
               length(Armature.Tokens.all())
    end

    test "contrast panel holds a single table", %{view: view} do
      doc = LazyHTML.from_fragment(render(view))
      assert Enum.count(LazyHTML.query(doc, "#catalogue-token-contrast table")) == 1
    end

    test "contrast table has one row per pair", %{view: view, values: values} do
      doc = LazyHTML.from_fragment(render(view))

      assert Enum.count(LazyHTML.query(doc, "#catalogue-token-contrast tbody tr")) ==
               length(values.light.pairs)
    end

    test "theme control applies to the token page", %{view: view} do
      view |> form("#catalogue-theme", %{theme: "dark"}) |> render_change()
      assert has_element?(view, "#armature-catalogue[data-armature-theme='dark']")
    end

    test "returning from an atom restores the token page", %{view: view} do
      view |> element("#catalogue-level-atom") |> render_click()
      view |> element("#catalogue-node-button") |> render_click()
      assert has_element?(view, "#catalogue-tokens")
      view |> element("#catalogue-tokens") |> render_click()
      assert has_element?(view, "#armature-catalogue-heading-tokens")
    end
  end

  # Each themed panel must show its tokens at work, not only label a group:
  # removing a demonstration fails here.
  describe "tokens page demonstrations" do
    setup do
      {:ok, view, _html} = live(build_conn(), "/ui?section=tokens")
      %{view: view}
    end

    test "surfaces panel paints every surface token", %{view: view} do
      for surface <- ~w(paper canvas stripe hover selected) do
        assert has_element?(
                 view,
                 "#catalogue-token-surfaces .armature-token-surface[style*='var(--armature-#{surface})']"
               )
      end

      assert has_element?(view, "#catalogue-token-surfaces [role=img][aria-label]")
    end

    test "accents panel applies accent tokens to live controls", %{view: view} do
      assert has_element?(view, "#catalogue-token-accents #catalogue-focus-sample")
      assert has_element?(view, "#catalogue-token-accents button[aria-pressed=true]")
      assert has_element?(view, "#catalogue-token-accents .armature-notice")
      assert has_element?(view, "#catalogue-token-accents .armature-select-wrap select")
      assert has_element?(view, "#catalogue-token-selection button[aria-pressed=true]")
      assert has_element?(view, "#catalogue-token-select.armature-select")
    end

    test "status panel shows every tone as status text or notice", %{view: view} do
      for tone <- ~w(success warning error) do
        assert has_element?(
                 view,
                 "#catalogue-token-status .armature-status.armature-tone-#{tone}"
               )

        assert has_element?(
                 view,
                 "#catalogue-token-status .armature-notice.armature-tone-#{tone}"
               )
      end
    end

    test "rail panel shows the rail at every width", %{view: view} do
      for width <- ~w(wide narrow) do
        assert has_element?(
                 view,
                 "#catalogue-token-rail .armature-token-rail-#{width} [aria-current=page]"
               )
      end

      assert has_element?(view, "#catalogue-token-rail .armature-grouped-nav")
    end

    test "typography panel sets every text size at every weight", %{view: view} do
      text_tokens =
        Enum.filter(Armature.Tokens.all(), &String.starts_with?(&1.name, "--armature-text-"))

      for token <- text_tokens, weight <- ~w(normal emphasis) do
        assert has_element?(
                 view,
                 "#catalogue-token-typography [style*='font-size: var(#{token.name})'][style*='--armature-weight-#{weight}']"
               )
      end

      assert has_element?(view, "#catalogue-token-typography #catalogue-tabular-sample")
    end

    test "space panel measures every space step", %{view: view} do
      for token <-
            Enum.filter(
              Armature.Tokens.all(),
              &Regex.match?(~r/--armature-space-(zero|half|\d+)$/, &1.name)
            ) do
        assert has_element?(
                 view,
                 "#catalogue-token-space .armature-token-space[style*='var(#{token.name})']"
               )
      end

      assert has_element?(view, "#catalogue-token-space .armature-stack .armature-cluster")

      assert view
             |> render()
             |> LazyHTML.from_fragment()
             |> LazyHTML.query("#catalogue-token-wrap .armature-token-surface")
             |> Enum.count() == 3
    end

    test "shape panel shows a sample for every shape state", %{view: view} do
      assert has_element?(view, "#catalogue-token-shape #catalogue-token-pressed")
      assert has_element?(view, "#catalogue-token-shape #catalogue-token-hover")

      assert has_element?(
               view,
               "#catalogue-token-shape .armature-sr-only#catalogue-token-hidden"
             )
    end

    test "density panel shows controls at every density", %{view: view} do
      for density <- ~w(default compact) do
        assert has_element?(view, "#catalogue-density-#{density} th button")
      end

      assert has_element?(view, "#catalogue-token-density .armature-search input[type=search]")
      assert has_element?(view, "#catalogue-token-search-search[type=search]")

      assert has_element?(
               view,
               "#catalogue-token-density #catalogue-token-inspector .armature-facts"
             )
    end

    test "motion panel animates at every speed", %{view: view} do
      for speed <- ~w(fast base) do
        assert has_element?(view, "#catalogue-motion-demo .armature-token-motion-#{speed}")
      end
    end
  end

  describe "index" do
    setup do
      {:ok, view, html} = live(build_conn(), "/ui")
      %{view: view, html: html}
    end

    test "renders a single Component catalogue heading", %{view: view, html: html} do
      assert has_element?(view, "h1", "Component catalogue")
      assert LazyHTML.from_fragment(html) |> LazyHTML.query("h1") |> Enum.count() == 1
    end

    test "groups components in level order", %{html: html} do
      levels =
        LazyHTML.from_fragment(html)
        |> LazyHTML.query("nav[aria-label='Components'] section")
        |> LazyHTML.attribute("data-level")

      assert levels == ~w(atom layout molecule organism template)
    end

    test "links to every registered node", %{view: view} do
      for node <- Armature.UI.Registry.nodes() do
        assert has_element?(view, "#catalogue-node-#{node.id}[href='/ui?node=#{node.id}']")
      end
    end
  end

  describe "relationship navigation" do
    setup do
      {:ok, view, _} = live(build_conn(), "/ui?node=field")
      %{view: view}
    end

    test "marks the current node", %{view: view} do
      assert has_element?(view, "#catalogue-node-field[aria-current='page']")
    end

    test "links to the components a node uses", %{view: view} do
      assert has_element?(view, "#catalogue-uses a[href='/ui?node=input']")
    end

    test "following a uses link patches to the used node", %{view: view} do
      follow_uses_link(view)
      assert_patch(view, "/ui?node=input")
    end

    test "the used node links back to the nodes that use it", %{view: view} do
      follow_uses_link(view)
      assert has_element?(view, "#catalogue-used-by a[href='/ui?node=field']")
    end

    test "the remounted heading can take focus", %{view: view} do
      follow_uses_link(view)
      assert has_element?(view, "#armature-catalogue-heading-input[tabindex='-1'][phx-mounted]")
    end

    test "returning to a node marks it current again", %{view: view} do
      follow_uses_link(view)
      render_patch(view, "/ui?node=field")
      assert has_element?(view, "#catalogue-node-field[aria-current='page']")
    end

    test "an unknown node falls back to the index", %{view: view} do
      render_patch(view, "/ui?node=unknown")
      assert has_element?(view, "h1", "Component catalogue")
    end

    test "an unknown node marks no component current", %{view: view} do
      render_patch(view, "/ui?node=unknown")
      refute has_element?(view, "nav[aria-label='Components'] [aria-current]")
    end
  end

  describe "every baseline node" do
    setup do
      {:ok, view, _} = live(build_conn(), "/ui")
      %{view: view}
    end

    test "renders examples", %{view: view} do
      for node <- Armature.UI.Registry.nodes() do
        render_patch(view, "/ui?node=#{node.id}")
        assert has_element?(view, "#catalogue-examples article")
        refute has_element?(view, "#catalogue-no-examples")
      end
    end

    test "renders usage notes", %{view: view} do
      for node <- Armature.UI.Registry.nodes() do
        render_patch(view, "/ui?node=#{node.id}")
        assert has_element?(view, "#catalogue-usage")
      end
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

  describe "theme control" do
    setup do
      {:ok, view, _} = live(build_conn(), "/ui")
      %{view: view}
    end

    # Auto sets no attribute, so the consumer's own :root tokens apply.
    test "auto sets no theme attribute", %{view: view} do
      refute has_element?(view, "#armature-catalogue[data-armature-theme]")
    end

    test "explicit themes set the theme attribute", %{view: view} do
      for theme <- ~w(dark light) do
        choose_theme(view, theme)
        assert has_element?(view, "#armature-catalogue[data-armature-theme='#{theme}']")
      end
    end

    test "returning to auto clears the theme attribute", %{view: view} do
      choose_theme(view, "dark")
      choose_theme(view, "auto")
      refute has_element?(view, "#armature-catalogue[data-armature-theme]")
    end

    test "unknown themes are ignored", %{view: view} do
      render_change(view, "catalogue:theme", %{"theme" => "unknown"})
      refute has_element?(view, "#armature-catalogue[data-armature-theme]")
      choose_theme(view, "dark")
      render_change(view, "catalogue:theme", %{"theme" => "unknown"})
      assert has_element?(view, "#armature-catalogue[data-armature-theme='dark']")
    end
  end

  describe "record examples" do
    setup do
      {:ok, view, _} = live(build_conn(), "/ui?node=table_inspector")
      %{view: view}
    end

    test "the example table uses compact density", %{view: view} do
      assert has_element?(view, "#example-records-table[data-density=compact]")
    end

    test "sorting a column twice reverses its direction", %{view: view} do
      view |> element("button[phx-value-key=score]") |> render_click()
      assert has_element?(view, "th[aria-sort=ascending]", "Score")
      view |> element("button[phx-value-key=score]") |> render_click()
      assert has_element?(view, "th[aria-sort=descending]", "Score")
    end

    test "next page announces the following range", %{view: view} do
      view |> element("button[aria-label='Next page']") |> render_click()
      assert has_element?(view, "#example-records-pagination-range", "26–50 of 200")
    end

    test "changing the page size returns to the first page", %{view: view} do
      view |> element("button[aria-label='Next page']") |> render_click()

      view
      |> form("#example-records-pagination-size-form", %{"page_size" => "10"})
      |> render_change()

      assert has_element?(view, "#example-records-pagination-range", "1–10 of 200")
    end

    test "search narrows the result count", %{view: view} do
      search(view, "R-001")
      assert has_element?(view, "#example-records-toolbar-count", "1 results")
    end

    test "selecting a row presses it", %{view: view} do
      select_first_record(view)
      assert has_element?(view, "button[phx-value-id=R-001][aria-pressed=true]")
    end

    test "selecting a row shows its details", %{view: view} do
      select_first_record(view)
      assert has_element?(view, "#example-selected-record", "R-001")
    end

    test "a search that excludes the selection keeps it", %{view: view} do
      select_first_record(view)
      search(view, "no match")
      assert has_element?(view, "#example-selected-record", "R-001")
    end

    test "a search that excludes the selection explains why it remains", %{view: view} do
      select_first_record(view)
      search(view, "no match")
      assert has_element?(view, "p", "The selected record is outside the current results.")
    end

    test "a search with no matches announces an empty range", %{view: view} do
      select_first_record(view)
      search(view, "no match")
      assert has_element?(view, "#example-records-pagination-range", "0–0 of 0")
    end

    test "selection survives navigating to the data_table example", %{view: view} do
      select_first_record(view)
      render_patch(view, "/ui?node=data_table")
      assert has_element?(view, "#example-selected-record", "R-001")
    end

    for {event, params} <- [
          {"record_select", %{"id" => "unknown"}},
          {"record_sort", %{"key" => "unknown"}},
          {"record_page", %{"page" => "invalid"}},
          {"record_size", %{"page_size" => "0"}}
        ] do
      @event event
      @params params

      test "an unknown #{event} value leaves the selection unchanged", %{view: view} do
        select_first_record(view)
        render_click(view, @event, @params)
        assert has_element?(view, "#example-selected-record", "R-001")
      end
    end
  end

  describe "action and form examples" do
    setup do
      {:ok, view, _} = live(build_conn(), "/ui?node=button")
      %{view: view}
    end

    test "example action counts activations", %{view: view} do
      view |> element("#example-action") |> render_click()
      assert has_element?(view, "p[role=status]", "Activated 1 times.")
    end

    test "blank names are marked invalid on submit", %{view: view} do
      submit_blank_name(view)
      assert has_element?(view, "#sample_name[aria-invalid=true]")
    end

    test "blank names are not saved", %{view: view} do
      submit_blank_name(view)
      refute has_element?(view, "#example-saved")
    end

    test "a corrected name clears invalid state", %{view: view} do
      submit_blank_name(view)
      view |> form("#sample-form", %{"sample" => %{"name" => "Sample"}}) |> render_change()
      refute has_element?(view, "#sample_name[aria-invalid=true]")
    end

    test "a corrected name saves", %{view: view} do
      submit_blank_name(view)
      view |> form("#sample-form", %{"sample" => %{"name" => "Sample"}}) |> render_change()
      view |> form("#sample-form", %{"sample" => %{"name" => "Sample"}}) |> render_submit()
      assert has_element?(view, "#example-saved[role=status]")
    end

    test "action state persists across navigation", %{view: view} do
      view |> element("#example-action") |> render_click()
      render_patch(view, "/ui?node=field")
      render_patch(view, "/ui?node=button")
      assert has_element?(view, "p[role=status]", "Activated 1 times.")
    end
  end

  describe "row label selection" do
    setup do
      {:ok, view, _} = live(build_conn(), "/ui?node=table_inspector")
      view |> form("#example-records-toolbar-search-form", %{query: "R-173"}) |> render_change()
      %{view: view}
    end

    test "search reveals the row label button", %{view: view} do
      assert has_element?(view, "#example-records-table-R-173 button", "Example 001")
    end

    test "selecting a row label announces the selection", %{view: view} do
      select_r173(view)
      assert has_element?(view, "#example-records-selection", "Selected R-173, Example 001.")
    end

    test "the selected row label is pressed", %{view: view} do
      select_r173(view)
      assert has_element?(view, "#example-records-table-R-173 button[aria-pressed=true]")
    end

    test "the selected row label controls the inspector", %{view: view} do
      select_r173(view)

      assert has_element?(
               view,
               "#example-records-table-R-173 button[aria-controls=example-records-inspector]"
             )
    end

    test "clearing search keeps the selection announced", %{view: view} do
      select_r173(view)
      search(view, "")
      assert has_element?(view, "#example-records-selection", "Selected R-173, Example 001.")
    end

    test "paging keeps the selection announced", %{view: view} do
      select_r173(view)
      search(view, "")
      view |> element("button[aria-label='Next page']") |> render_click()
      assert has_element?(view, "#example-records-selection", "Selected R-173, Example 001.")
    end

    test "paging keeps the selected record in the inspector", %{view: view} do
      select_r173(view)
      search(view, "")
      view |> element("button[aria-label='Next page']") |> render_click()
      assert has_element?(view, "#example-selected-record", "R-173")
    end
  end

  describe "clearing search" do
    setup do
      {:ok, view, _} = live(build_conn(), "/ui?node=table_inspector")
      search(view, "R-001")
      %{view: view}
    end

    test "a search offers a named clear button", %{view: view} do
      assert has_element?(view, "#example-records-toolbar-clear[aria-label='Clear search']")
    end

    test "clearing search empties the search input", %{view: view} do
      view |> element("#example-records-toolbar-clear") |> render_click()
      assert has_element?(view, "#example-records-toolbar-search[value='']")
    end

    test "clearing search restores the full result count", %{view: view} do
      view |> element("#example-records-toolbar-clear") |> render_click()
      assert has_element?(view, "#example-records-toolbar-count", "200 results")
    end

    test "clearing search hides the clear button", %{view: view} do
      view |> element("#example-records-toolbar-clear") |> render_click()
      refute has_element?(view, "#example-records-toolbar-clear")
    end
  end

  describe "aliased nested scope" do
    setup do
      {:ok, view, _} = live(build_conn(), "/nested/ui?node=marker")
      %{view: view}
    end

    test "links nodes under its own path", %{view: view} do
      assert has_element?(
               view,
               "#catalogue-node-marker[aria-current=page][href='/nested/ui?node=marker']"
             )

      assert has_element?(view, "#catalogue-node-button[href='/nested/ui?node=button']")
    end

    test "renders consumer extension examples", %{view: view} do
      assert has_element?(view, "#example-extension", "Example extension")
    end

    test "renders consumer extension usage notes", %{view: view} do
      assert has_element?(view, "#catalogue-usage", "A synthetic extension with a visible name.")
    end
  end

  defp choose_destination(view, destination) do
    view
    |> form("#catalogue-components-form", %{destination: destination})
    |> render_change()
  end

  defp choose_width(view, width) do
    view |> form("#catalogue-preview-form", %{width: width}) |> render_change()
  end

  defp choose_theme(view, theme) do
    view |> form("#catalogue-theme", %{"theme" => theme}) |> render_change()
  end

  defp follow_uses_link(view) do
    view |> element("#catalogue-uses a[href='/ui?node=input']") |> render_click()
  end

  defp token_row(token), do: "#token-#{String.trim_leading(token.name, "--")}"

  defp contrast_row(pair) do
    "#catalogue-token-contrast tr" <>
      "[data-foreground='#{pair.foreground}'][data-background='#{pair.background}']"
  end

  defp search(view, query) do
    view |> form("#example-records-toolbar-search-form", %{"query" => query}) |> render_change()
  end

  defp select_first_record(view) do
    search(view, "R-001")
    view |> element("#example-records-table-R-001") |> render_click()
  end

  defp select_r173(view) do
    view |> element("#example-records-table-R-173 button") |> render_click()
  end

  defp submit_blank_name(view) do
    render_patch(view, "/ui?node=field")
    view |> form("#sample-form", %{"sample" => %{"name" => ""}}) |> render_submit()
  end
end
