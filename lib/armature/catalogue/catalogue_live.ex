defmodule Armature.Catalogue.CatalogueLive do
  @moduledoc false
  use Phoenix.LiveView
  alias Phoenix.LiveView.JS

  def on_mount({registry, examples}, _params, _session, socket) do
    Code.ensure_loaded!(examples)
    state = if function_exported?(examples, :init, 0), do: examples.init(), else: %{}

    {:cont,
     assign(socket,
       nodes: registry.nodes(),
       examples_module: examples,
       example_state: state,
       theme: "auto"
     )}
  end

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def handle_params(params, uri, socket) do
    node = Enum.find(socket.assigns.nodes, &(to_string(&1.id) == params["node"]))
    path = URI.parse(uri).path

    {:noreply,
     assign(socket,
       node: node,
       path: path,
       examples: if(node, do: socket.assigns.examples_module.examples(node.id), else: []),
       usage: if(node, do: usage(node), else: ""),
       uses: if(node, do: Enum.filter(socket.assigns.nodes, &(&1.id in node.uses)), else: []),
       used_by: if(node, do: Enum.filter(socket.assigns.nodes, &(node.id in &1.uses)), else: [])
     )}
  end

  @impl true
  def handle_event("catalogue:theme", %{"theme" => theme}, socket)
      when theme in ~w(auto light dark),
      do: {:noreply, assign(socket, theme: theme)}

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
    ~H"""
    <div id="armature-catalogue" class={["armature-catalogue"]} data-armature-theme={@theme}>
      <form id="catalogue-theme" phx-change="catalogue:theme" phx-submit="catalogue:theme">
        <label for="catalogue-theme-choice">Example theme</label>
        <select id="catalogue-theme-choice" name="theme" class={["armature-select"]}>
          <option :for={theme <- ~w(auto light dark)} value={theme} selected={theme == @theme}>
            {String.capitalize(theme)}
          </option>
        </select>
      </form>
      <div class={["armature-catalogue-columns"]}>
        <nav aria-label="Components">
          <.link patch={@path}>Catalogue index</.link>
          <section :for={level <- Armature.Registry.levels()} data-level={level}>
            <h2>{level_name(level)}</h2>
            <ul>
              <li :for={item <- Enum.filter(@nodes, &(&1.level == level))}>
                <.link
                  id={"catalogue-node-#{item.id}"}
                  patch={node_path(@path, item)}
                  aria-current={if @node && @node.id == item.id, do: "page"}
                >
                  {item.id}
                </.link>
              </li>
            </ul>
          </section>
        </nav>
        <div class={["armature-catalogue-detail"]}>
          <h1
            id={"armature-catalogue-heading-#{if @node, do: @node.id, else: "index"}"}
            tabindex="-1"
            phx-mounted={JS.focus()}
          >
            {if @node, do: @node.id, else: "Component catalogue"}
          </h1>
          <%= if @node do %>
            <p>Level: {@node.level}</p>
            <p>{@node.purpose}</p>
            <section id="catalogue-examples" aria-label="Live examples">
              <h2>Live examples</h2>
              <p :if={@examples == []} id="catalogue-no-examples">
                No examples supplied for this component.
              </p>
              <article :for={example <- @examples}>
                <h3>{example.title}</h3>
                <p>{example.description}</p>
                {example.render.(%{state: @example_state, __changed__: nil})}
              </article>
            </section>
            <section id="catalogue-usage">
              <h2>Usage and accessibility notes</h2>
              <div class={["armature-catalogue-notes"]}>{@usage}</div>
            </section>
            <section id="catalogue-uses">
              <h2>Uses</h2>
              <p :if={@uses == []}>No registered ingredients.</p>
              <ul>
                <li :for={item <- @uses}><.link patch={node_path(@path, item)}>{item.id}</.link></li>
              </ul>
            </section>
            <section id="catalogue-used-by">
              <h2>Used by</h2>
              <p :if={@used_by == []}>No registered dependants.</p>
              <ul>
                <li :for={item <- @used_by}>
                  <.link patch={node_path(@path, item)}>{item.id}</.link>
                </li>
              </ul>
            </section>
          <% else %>
            <p>Choose a component to explore its purpose, examples, usage and relationships.</p>
          <% end %>
        </div>
      </div>
    </div>
    """
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
