defmodule Armature.Catalogue.PreviewTest do
  use ExUnit.Case, async: true

  alias Armature.Catalogue.Preview

  describe "isolated?/1" do
    test "isolates a main element in any case" do
      assert Preview.isolated?("<main>x</main>")
      assert Preview.isolated?("<MAIN>x</MAIN>")
    end

    test "isolates explicit page landmark roles" do
      assert Preview.isolated?(~s(<div role="main"></div>))
      assert Preview.isolated?(~s(<div role='banner'></div>))
      assert Preview.isolated?(~s(<div role="contentinfo"></div>))
    end

    test "isolates a top-level header or footer" do
      assert Preview.isolated?("<header>x</header>")
      assert Preview.isolated?("<footer>x</footer>")
    end

    test "isolates a header inside a non-sectioning wrapper" do
      assert Preview.isolated?(~s(<div class="x"><header>x</header></div>))
    end

    test "keeps a header or footer inside a sectioning element inline" do
      refute Preview.isolated?("<aside><header>x</header></aside>")
      refute Preview.isolated?("<section><footer>x</footer></section>")
      refute Preview.isolated?("<nav><header>x</header></nav>")
      refute Preview.isolated?("<article><footer>x</footer></article>")
    end

    test "isolates a header after its sectioning element has closed" do
      assert Preview.isolated?("<section><p>x</p></section><header>x</header>")
    end

    test "closing a sectioning element pops through an unclosed child" do
      assert Preview.isolated?("<section><div></section><header>x</header>")
    end

    test "closing a tag that is not open leaves the stack unchanged" do
      assert Preview.isolated?("</span><header>x</header>")
    end

    test "void and self-closing tags never open a scope" do
      assert Preview.isolated?("<img><br/><input><header>x</header>")
    end

    test "keeps plain content inline" do
      refute Preview.isolated?("<button>Go</button>")
    end
  end

  describe "document/3" do
    defp parse(html), do: LazyHTML.from_document(html)

    test "sets the language and an explicit theme on the root element" do
      document = parse(Preview.document("<p>x</p>", "dark", ":root{}"))
      html = LazyHTML.query(document, "html")

      assert LazyHTML.attribute(html, "lang") == ["en"]
      assert LazyHTML.attribute(html, "data-armature-theme") == ["dark"]
    end

    test "leaves the theme attribute off when the theme is auto" do
      document = parse(Preview.document("<p>x</p>", "auto", ":root{}"))

      assert LazyHTML.attribute(LazyHTML.query(document, "html"), "data-armature-theme") == []
    end

    test "embeds the stylesheet and the body margin rule" do
      document = parse(Preview.document("<p>x</p>", "auto", ":root{}"))
      style = document |> LazyHTML.query("style") |> LazyHTML.text()

      assert style =~ ":root{}"
      assert style =~ "body { margin: var(--armature-space-zero); }"
    end

    test "places the example markup in the body" do
      document = parse(Preview.document(~s(<p id="example">x</p>), "auto", ":root{}"))

      assert document |> LazyHTML.query("body #example") |> LazyHTML.text() == "x"
    end
  end
end
