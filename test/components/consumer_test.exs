defmodule Example.UI.Consumer do
  @moduledoc false
  use Phoenix.Component
  use Armature.Components
  import Phoenix.Component, except: [link: 1]

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
  use Armature.ComponentsCase, async: true

  test "the documented consumer imports render the example form" do
    doc =
      document(&Example.UI.Consumer.example/1, %{
        form: to_form(%{"name" => "Example"}, as: :sample)
      })

    assert present?(doc, "form#example-form input#sample_name[value=Example]")
    assert present?(doc, "#example-form button.armature-button[type=submit]")
    assert text(doc, "#example-form a.armature-link[href='/']") == "Return"
  end
end
