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

  test "configured consumer stylesheet changes server contrast results" do
    {:ok, view, _html} = live(build_conn(), "/overrides?section=tokens")
    assert has_element?(view, "#token-armature-ink tr[data-theme='light'] td", "1.00:1")
    assert has_element?(view, "#token-armature-ink tr[data-theme='light'] td", "Fail")
    assert has_element?(view, "#token-armature-ink tr[data-theme='explicit_light'] td", "Fail")
    assert has_element?(view, "#token-armature-ink tr[data-theme='dark'] td", "Pass")
  end

  test "tokens precede atoms and show contract samples and both theme results" do
    {:ok, view, _html} = live(build_conn(), "/ui?section=tokens")
    assert has_element?(view, "nav > a:first-child#catalogue-tokens[aria-current='page']")
    assert has_element?(view, "#armature-catalogue-heading-tokens", "Tokens")
    assert has_element?(view, "#token-armature-ink .armature-token-swatch")
    assert has_element?(view, "#token-armature-ink tr[data-theme='light']", "Pass")
    assert has_element?(view, "#token-armature-ink tr[data-theme='dark']", "Pass")
    assert has_element?(view, "#token-armature-text-base .armature-token-type")
    assert has_element?(view, "#token-armature-space-4 .armature-token-space")
    assert has_element?(view, "#token-armature-radius-base .armature-token-radius")
    assert has_element?(view, "#token-armature-control-height-compact .armature-token-height")
    assert has_element?(view, "#catalogue-focus-sample")
    assert has_element?(view, "#catalogue-tabular-sample")

    for token <- Armature.Tokens.all() do
      assert has_element?(view, "#token-#{String.trim_leading(token.name, "--")}")
    end

    view |> form("#catalogue-theme", %{theme: "dark"}) |> render_change()
    assert has_element?(view, "#armature-catalogue[data-armature-theme='dark']")
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
    view |> element("button[phx-value-id=R-001]") |> render_click()
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
