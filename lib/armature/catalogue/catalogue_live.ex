defmodule Armature.Catalogue.CatalogueLive do
  @moduledoc false
  use Phoenix.LiveView
  alias Phoenix.LiveView.JS
  alias Armature.Components, as: A

  @external_resource "priv/static/armature.css"
  @stylesheet File.read!(@external_resource)
  @preview_widths ~w(wide 800 520 375)

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
    nodes = socket.assigns.nodes
    selected_node = Enum.find(nodes, &(to_string(&1.id) == params["node"]))
    level = Enum.find(Armature.Registry.levels(), &(to_string(&1) == params["level"]))
    node = selected_node || if(level, do: Enum.find(nodes, &(&1.level == level)))
    level = if node, do: node.level, else: level
    path = URI.parse(uri).path
    tokens? = params["section"] == "tokens"
    heading_key = if tokens?, do: "tokens", else: if(node, do: node.id, else: "index")

    heading =
      if tokens?,
        do: "Tokens",
        else: if(node, do: to_string(node.id), else: "Component catalogue")

    section = if tokens?, do: "Tokens", else: if(level, do: level_name(level), else: "Catalogue")

    {:noreply,
     assign(socket,
       node: node,
       level: level,
       heading_id: "armature-catalogue-heading-#{heading_key}",
       heading: heading,
       eyebrow: "Library / " <> section,
       tokens?: tokens?,
       path: path,
       examples: if(node, do: socket.assigns.examples_module.examples(node.id), else: []),
       usage: if(node, do: usage(node), else: ""),
       uses: if(node, do: Enum.filter(socket.assigns.nodes, &(&1.id in node.uses)), else: []),
       used_by: if(node, do: Enum.filter(socket.assigns.nodes, &(node.id in &1.uses)), else: [])
     )}
  end

  @impl true
  def handle_event("catalogue:choose", %{"destination" => destination}, socket) do
    if Enum.any?(socket.assigns.nodes, &(node_path(socket.assigns.path, &1) == destination)) do
      {:noreply, push_patch(socket, to: destination)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("catalogue:theme", %{"theme" => theme}, socket)
      when theme in ~w(auto light dark),
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
    assigns = assign(assigns, previews: previews, preview_widths: @preview_widths)

    ~H"""
    <A.app_shell
      id="armature-catalogue"
      title={@title}
      home_patch={@path}
      items={rail_items(@path, @level, @tokens?)}
      context={@title <> " / Component catalogue"}
      heading={@heading}
      heading_id={@heading_id}
      heading_rest={%{"phx-mounted" => JS.focus()}}
      eyebrow={@eyebrow}
      data-armature-theme={if @theme != "auto", do: @theme}
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
                  class={["armature-theme-switch"]}
                  phx-change="catalogue:width"
                  phx-submit="catalogue:width"
                >
                  <label for="catalogue-preview-width">Preview width</label>
                  <A.select
                    id="catalogue-preview-width"
                    name="width"
                    value={@preview_width}
                    options={Enum.map(@preview_widths, &{width_label(&1), &1})}
                    aria-describedby="catalogue-preview-status"
                  />
                  <p id="catalogue-preview-status" role="status" aria-live="polite">
                    Preview width: {width_label(@preview_width)}
                  </p>
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
                    <A.link patch={node_path(@path, item)}>{item.id}</A.link>
                  </li>
                </ul>
              </section>
              <section id="catalogue-used-by">
                <h2>Used by</h2>
                <p :if={@used_by == []}>No registered dependants.</p>
                <ul>
                  <li :for={item <- @used_by}>
                    <A.link patch={node_path(@path, item)}>{item.id}</A.link>
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

    isolated? = page_landmark?(html)

    Map.merge(example, %{content: content, html: html, isolated?: isolated?})
  end

  @sectioning ~w(article aside main nav section)
  @void ~w(area base br col embed hr img input link meta param source track wbr)

  # True when the example would add a page-level landmark to the catalogue's
  # own document: a main element, an explicit main, banner or contentinfo
  # role, or a header or footer that no sectioning element contains. Such
  # examples render in their own document. A header inside an aside is not a
  # page landmark, so interactive compositions stay inline and keep working.
  defp page_landmark?(html) do
    if Regex.match?(~r/<main\b|role=["'](?:main|banner|contentinfo)["']/i, html) do
      true
    else
      ~r/<(\/?)([a-zA-Z][\w-]*)\b[^>]*?(\/?)>/
      |> Regex.scan(html)
      |> Enum.reduce_while([], fn [_, closing, name, self_closing], stack ->
        name = String.downcase(name)

        cond do
          closing == "/" ->
            {:cont, drop_to(stack, name)}

          name in ~w(header footer) and not Enum.any?(stack, &(&1 in @sectioning)) ->
            {:halt, :landmark}

          self_closing == "/" or name in @void ->
            {:cont, stack}

          true ->
            {:cont, [name | stack]}
        end
      end)
      |> Kernel.==(:landmark)
    end
  end

  defp drop_to(stack, name) do
    case Enum.split_while(stack, &(&1 != name)) do
      {_inner, [^name | rest]} -> rest
      {_inner, []} -> stack
    end
  end

  defp example_preview(assigns) do
    theme = if assigns.theme == "auto", do: "", else: ~s(data-armature-theme="#{assigns.theme}")

    document =
      ~s(<!doctype html><html lang="en" #{theme}><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><style>) <>
        @stylesheet <>
        "body { margin: var(--armature-space-zero); }</style></head><body>" <>
        assigns.example.html <> "</body></html>"

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
          label: level_name(item),
          patch: path <> "?level=#{item}",
          current: !tokens? && level == item
        }
      end)
  end

  defp component_groups(nodes, path, level, node) do
    levels = if level, do: [level], else: Armature.Registry.levels()

    Enum.map(levels, fn item ->
      %{
        label: level_name(item),
        level: item,
        items:
          nodes
          |> Enum.filter(&(&1.level == item))
          |> Enum.map(fn component ->
            %{
              id: "catalogue-node-#{component.id}",
              label: to_string(component.id),
              patch: node_path(path, component),
              current: node != nil && node.id == component.id
            }
          end)
      }
    end)
  end

  defp level_name(level), do: level |> to_string() |> String.capitalize() |> Kernel.<>("s")
  defp node_path(path, node), do: path <> "?" <> URI.encode_query(%{"node" => node.id})

  defp usage(node) do
    with {:docs_v1, _, _, _, _, _, docs} <- Code.fetch_docs(node.module),
         {_, _, _, %{"en" => text}, _} <-
           Enum.find(docs, fn {identity, _, _, _, _} ->
             identity == {:function, node.function, 1}
           end) do
      text
    else
      _ -> "No usage documentation available."
    end
  end
end
