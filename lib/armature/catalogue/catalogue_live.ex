defmodule Armature.Catalogue.CatalogueLive do
  @moduledoc false
  use Phoenix.LiveView
  alias Phoenix.LiveView.JS
  alias Armature.Catalogue.{Page, Preview}
  alias Armature.Components, as: A

  @external_resource "priv/static/armature.css"
  @stylesheet File.read!("priv/static/armature.css")
  # The catalogue's own presentation travels with the page, so consumers load only armature.css.
  @external_resource "priv/catalogue/catalogue.css"
  @catalogue_stylesheet File.read!("priv/catalogue/catalogue.css")
  @preview_widths ~w(wide 800 520 375)
  @themes Armature.Components.themes()

  def on_mount({registry, examples, token_stylesheets, title}, _params, _session, socket) do
    Code.ensure_loaded!(examples)
    state = if function_exported?(examples, :init, 0), do: examples.init(), else: %{}

    {:cont,
     assign(socket,
       title: title,
       nodes: registry.nodes(),
       examples_module: examples,
       example_state: state,
       theme: "auto",
       preview_width: "wide",
       token_values: Armature.Tokens.Values.read(token_stylesheets)
     )}
  end

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(params, uri, socket) do
    %{node: node} = page = Page.resolve(socket.assigns.nodes, params)

    {:noreply,
     socket
     |> assign(page)
     |> assign(
       path: URI.parse(uri).path,
       examples: if(node, do: socket.assigns.examples_module.examples(node.id), else: []),
       usage: if(node, do: Page.usage(node), else: "")
     )}
  end

  @impl true
  def handle_event("catalogue:choose", %{"destination" => destination}, socket) do
    if Enum.any?(socket.assigns.nodes, &(Page.node_path(socket.assigns.path, &1) == destination)) do
      {:noreply, push_patch(socket, to: destination)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("catalogue:theme", %{"theme" => theme}, socket)
      when theme in @themes,
      do: {:noreply, assign(socket, theme: theme)}

  def handle_event("catalogue:width", %{"width" => width}, socket)
      when width in @preview_widths do
    {:noreply, assign(socket, :preview_width, width)}
  end

  def handle_event("catalogue:width", _params, socket), do: {:noreply, socket}

  def handle_event("catalogue:" <> _event, _params, socket), do: {:noreply, socket}

  def handle_event(event, params, socket) do
    module = socket.assigns.examples_module

    state =
      if function_exported?(module, :handle_event, 3),
        do: module.handle_event(event, params, socket.assigns.example_state),
        else: socket.assigns.example_state

    {:noreply, assign(socket, example_state: state)}
  end

  @impl true
  def render(assigns) do
    previews = Enum.map(assigns.examples, &prepare_preview(&1, assigns.example_state))

    assigns =
      assign(assigns,
        previews: previews,
        preview_widths: @preview_widths,
        catalogue_stylesheet: @catalogue_stylesheet
      )

    ~H"""
    <style id="armature-catalogue-stylesheet">
      <%= Phoenix.HTML.raw(@catalogue_stylesheet) %>
    </style>
    <A.app_shell
      id="armature-catalogue"
      title={@title}
      subtitle="Component catalogue"
      nav_label="Library sections"
      section_label="Library"
      home_patch={@path}
      items={rail_items(@path, @level, @tokens?)}
      context={@title <> " / Component catalogue"}
      heading={@heading}
      heading_id={@heading_id}
      heading_rest={%{"phx-mounted" => JS.focus()}}
      eyebrow={@eyebrow}
      data-armature-theme={A.theme_attribute(@theme)}
    >
      <:footnote>Live components · Synthetic examples · Refresh resets examples</:footnote>
      <:top_actions>
        <A.theme_switch
          id="catalogue-theme"
          value={@theme}
          label="Example theme"
          event="catalogue:theme"
        />
      </:top_actions>
      <%= if @tokens? do %>
        <Armature.Catalogue.TokenPage.page values={@token_values} theme={@theme} />
      <% else %>
        <div class={["armature-catalogue-explorer"]}>
          <A.grouped_nav
            id="catalogue-components"
            label="Components"
            event="catalogue:choose"
            groups={component_groups(@nodes, @path, @level, @node)}
          />
          <div class={["armature-catalogue-detail"]}>
            <%= if @node do %>
              <p>Level: {@node.level}</p>
              <p>{@node.purpose}</p>
              <section id="catalogue-examples" aria-label="Live examples">
                <h2>Live examples</h2>
                <p :if={@examples == []} id="catalogue-no-examples">
                  No examples supplied for this component.
                </p>
                <form
                  :if={Enum.any?(@previews, & &1.isolated?)}
                  id="catalogue-preview-form"
                  phx-change="catalogue:width"
                  phx-submit="catalogue:width"
                >
                  <A.cluster>
                    <A.field
                      type="select"
                      id="catalogue-preview-width"
                      name="width"
                      label="Preview width"
                      value={@preview_width}
                      options={Enum.map(@preview_widths, &{width_label(&1), &1})}
                      aria-describedby="catalogue-preview-status"
                    />
                    <p id="catalogue-preview-status" role="status" aria-live="polite">
                      Preview width: {width_label(@preview_width)}
                    </p>
                  </A.cluster>
                </form>
                <div class={["armature-catalogue-panels"]}>
                  <div class={["armature-catalogue-panel-items"]}>
                    <article :for={{example, index} <- Enum.with_index(@previews)}>
                      <A.panel id={"catalogue-example-#{@node.id}-#{index}"} heading={example.title}>
                        <p>{example.description}</p>
                        <.example_preview
                          example={example}
                          node={@node}
                          theme={@theme}
                          width={@preview_width}
                        />
                      </A.panel>
                    </article>
                  </div>
                </div>
              </section>
              <section id="catalogue-usage">
                <h2>Usage and accessibility notes</h2>
                <div class={["armature-catalogue-notes"]}>{@usage}</div>
              </section>
              <section id="catalogue-uses">
                <h2>Uses</h2>
                <p :if={@uses == []}>No registered ingredients.</p>
                <ul>
                  <li :for={item <- @uses}>
                    <A.link patch={Page.node_path(@path, item)}>{item.id}</A.link>
                  </li>
                </ul>
              </section>
              <section id="catalogue-used-by">
                <h2>Used by</h2>
                <p :if={@used_by == []}>No registered dependants.</p>
                <ul>
                  <li :for={item <- @used_by}>
                    <A.link patch={Page.node_path(@path, item)}>{item.id}</A.link>
                  </li>
                </ul>
              </section>
            <% else %>
              <p>Choose a component to explore its purpose, examples, usage and relationships.</p>
            <% end %>
          </div>
        </div>
      <% end %>
    </A.app_shell>
    """
  end

  defp prepare_preview(example, state) do
    content = example.render.(%{state: state, __changed__: nil})
    html = Phoenix.HTML.Safe.to_iodata(content) |> IO.iodata_to_binary()

    Map.merge(example, %{content: content, html: html, isolated?: Preview.isolated?(html)})
  end

  defp example_preview(assigns) do
    document = Preview.document(assigns.example.html, assigns.theme, @stylesheet)
    assigns = assign(assigns, :document, document)

    ~H"""
    <%= if @example.isolated? do %>
      <div class={["armature-catalogue-preview-scroll"]}>
        <iframe
          class={["armature-catalogue-preview"]}
          title={"#{@node.id}: #{@example.title}"}
          srcdoc={@document}
          width={if @width == "wide", do: "100%", else: @width}
        />
      </div>
    <% else %>
      {@example.content}
    <% end %>
    """
  end

  defp width_label("wide"), do: "Wide"
  defp width_label(width), do: width <> "px"

  defp rail_items(path, level, tokens?) do
    [
      %{
        id: "catalogue-tokens",
        label: "Tokens",
        patch: path <> "?section=tokens",
        current: tokens?
      }
    ] ++
      Enum.map(Armature.Registry.levels(), fn item ->
        %{
          id: "catalogue-level-#{item}",
          label: Armature.Registry.level_name(item),
          patch: path <> "?level=#{item}",
          current: !tokens? && level == item
        }
      end)
  end

  defp component_groups(nodes, path, level, node) do
    levels = if level, do: [level], else: Armature.Registry.levels()

    Enum.map(levels, fn item ->
      %{
        label: Armature.Registry.level_name(item),
        level: item,
        items:
          nodes
          |> Enum.filter(&(&1.level == item))
          |> Enum.map(fn component ->
            %{
              id: "catalogue-node-#{component.id}",
              label: to_string(component.id),
              patch: Page.node_path(path, component),
              current: node != nil && node.id == component.id
            }
          end)
      }
    end)
  end
end
