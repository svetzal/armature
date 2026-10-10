# A one-file preview of Armature's baseline components.
#
#     elixir examples/preview.exs
#
# It loads Armature from this checkout, so edits to lib/ or priv/ show on the
# next start. Set PORT to change the port (default 4020). This is a development
# aid only: it is not part of the Hex package. The registry-driven catalogue
# (a later step) replaces it.

Mix.install([
  {:phoenix_playground, "~> 0.1.9"},
  {:armature, path: Path.expand("..", __DIR__)}
])

Code.require_file("records.exs", __DIR__)

defmodule PreviewLive do
  use Phoenix.LiveView

  alias Armature.Components, as: A

  @stylesheet Path.expand("../priv/static/armature.css", __DIR__)

  @page_css """
  .preview { min-height: 100vh; background: var(--armature-canvas); color: var(--armature-ink);
    font-family: var(--armature-font-sans); line-height: var(--armature-line-height); }
  .preview-inner { max-width: 64rem; margin: 0 auto; padding: var(--armature-space-6, 2rem) var(--armature-space-4, 1rem); }
  .preview h1 { font-size: var(--armature-text-heading); margin: 0; }
  .preview h2 { font-size: var(--armature-text-large); margin: 0 0 var(--armature-space-3) 0; }
  .preview section { background: var(--armature-paper); border: 1px solid var(--armature-line);
    border-radius: 6px; padding: var(--armature-space-4, 1rem); margin-top: var(--armature-space-4, 1rem); }
  .preview .muted { color: var(--armature-muted); font-size: var(--armature-text-small); margin: 0; }
  .preview .box { background: var(--armature-canvas); border: 1px dashed var(--armature-line);
    padding: var(--armature-space-3); border-radius: 4px; }
  .preview .swatch { display: inline-flex; align-items: center; gap: var(--armature-space-2);
    font-family: var(--armature-font-mono); font-size: var(--armature-text-small); }
  .preview .chip { width: 1.5rem; height: 1.5rem; border-radius: 4px; border: 1px solid var(--armature-line); }
  """

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       theme: "auto",
       stylesheet: File.read!(@stylesheet),
       colours: for(t <- Armature.Tokens.all(), t.group == :colour, do: t.name),
       form: to_form(%{"name" => "", "accepted" => false}, as: :sample),
       saved: nil,
       query: "",
       sort_by: "name",
       sort_direction: "asc",
       page: 1,
       page_size: 25,
       selected_id: nil,
       selected: nil,
       selection_label: "No record selected."
     )
     |> refresh_records()}
  end

  def handle_event("theme", %{"theme" => theme}, socket),
    do: {:noreply, assign(socket, theme: theme)}

  def handle_event("validate", %{"sample" => params}, socket) do
    {:noreply, assign(socket, form: form_for(params), saved: nil)}
  end

  def handle_event("save", %{"sample" => params}, socket) do
    form = form_for(params)

    if form.errors == [] do
      {:noreply, assign(socket, form: form, saved: params)}
    else
      {:noreply, assign(socket, form: form, saved: nil)}
    end
  end

  def handle_event("record_search", %{"query" => query}, socket) do
    {:noreply, socket |> assign(query: query, page: 1) |> refresh_records()}
  end

  def handle_event("record_sort", %{"key" => key}, socket) when key in ~w(name score) do
    direction =
      if socket.assigns.sort_by == key && socket.assigns.sort_direction == "asc",
        do: "desc",
        else: "asc"

    {:noreply,
     socket |> assign(sort_by: key, sort_direction: direction, page: 1) |> refresh_records()}
  end

  def handle_event("record_page", %{"page" => page}, socket) do
    {:noreply, socket |> assign(page: String.to_integer(page)) |> refresh_records()}
  end

  def handle_event("record_size", %{"page_size" => size}, socket) when size in ~w(10 25 50) do
    {:noreply, socket |> assign(page_size: String.to_integer(size), page: 1) |> refresh_records()}
  end

  def handle_event("record_select", %{"id" => id}, socket) do
    case Enum.find(PreviewRecords.all(), &(&1.id == id)) do
      nil ->
        {:noreply, socket}

      record ->
        {:noreply,
         assign(socket,
           selected_id: id,
           selected: record,
           selection_label: "Selected #{id}, #{record.name}."
         )}
    end
  end

  defp refresh_records(socket) do
    result = PreviewRecords.page(socket.assigns)
    assign(socket, records: result, page: result.page)
  end

  defp form_for(params) do
    errors =
      if String.trim(params["name"] || "") == "", do: [name: {"Enter a name.", []}], else: []

    to_form(params, as: :sample, errors: errors)
  end

  def render(assigns) do
    ~H"""
    <%!-- HEEx does not interpolate {} inside <style>; EEx tags do. --%>
    <style>
      <%= Phoenix.HTML.raw(@stylesheet) %><%= Phoenix.HTML.raw(page_css()) %>
    </style>
    <div class="preview" data-armature-theme={if @theme != "auto", do: @theme}>
      <div class="preview-inner">
        <A.stack>
          <A.cluster>
            <h1>Armature preview</h1>
            <A.status label={"Theme: #{@theme}"} />
          </A.cluster>
          <p class="muted">
            Baseline controls and data components, in their states. The theme buttons set <code>data-armature-theme</code>; "auto" follows your system setting.
          </p>
          <A.cluster>
            <A.button
              :for={t <- ~w(auto light dark)}
              variant={if t == @theme, do: "primary", else: "secondary"}
              phx-click="theme"
              phx-value-theme={t}
            >
              {String.capitalize(t)}
            </A.button>
          </A.cluster>
        </A.stack>

        <section>
          <h2>Buttons and links</h2>
          <A.cluster>
            <A.button>Primary action</A.button>
            <A.button variant="secondary">Secondary action</A.button>
            <A.button disabled>Disabled</A.button>
            <A.button variant="secondary" disabled>Disabled secondary</A.button>
            <A.button variant="secondary">
              <A.icon>
                <svg viewBox="0 0 16 16" width="16" height="16" fill="currentColor">
                  <path d="M8 1.5a.75.75 0 0 1 .75.75v5h5a.75.75 0 0 1 0 1.5h-5v5a.75.75 0 0 1-1.5 0v-5h-5a.75.75 0 0 1 0-1.5h5v-5A.75.75 0 0 1 8 1.5Z" />
                </svg>
              </A.icon>
              Add item
            </A.button>
            <A.link href="#">A plain link</A.link>
          </A.cluster>
        </section>

        <section>
          <h2>Status badges</h2>
          <A.cluster>
            <A.status label="Draft" />
            <A.status tone="success" label="Received" />
            <A.status tone="warning" label="Partly received" />
            <A.status tone="error" label="Overdue" />
          </A.cluster>
        </section>

        <section>
          <h2>Notices</h2>
          <A.stack>
            <A.notice id="n-neutral" title="For information">
              Static guidance has no live-region role.
            </A.notice>
            <A.notice id="n-success" tone="success" result title="Saved">
              A result: announced politely as a status.
            </A.notice>
            <A.notice id="n-warning" tone="warning" result title="Check the quantity">
              8 of 24 received. The rest stays on order.
              <:actions><A.button variant="secondary">Review</A.button></:actions>
            </A.notice>
            <A.notice id="n-error" tone="error" result title="Could not save">
              An error result: announced as an alert.
            </A.notice>
          </A.stack>
        </section>

        <section>
          <h2>Fields</h2>
          <p class="muted">
            Leave the name empty and move on, or press Save, to see the error.
            Errors appear only after the field has been used.
          </p>
          <.form for={@form} id="sample-form" phx-change="validate" phx-submit="save">
            <A.stack>
              <A.field field={@form[:name]} label="Name" hint="The name people will see." />
              <A.field
                field={@form[:size]}
                type="select"
                label="Size"
                prompt="Choose a size"
                options={[{"Small", "s"}, {"Medium", "m"}, {"Large", "l"}]}
              />
              <A.field field={@form[:notes]} type="textarea" label="Notes" rows="3" />
              <A.field field={@form[:accepted]} type="checkbox" label="I accept the terms" />
              <A.field
                id="locked"
                name="locked"
                value="Fixed value"
                label="Read-only field"
                hint="Disabled controls keep their label."
                disabled
              />
              <A.cluster>
                <A.button type="submit">Save</A.button>
              </A.cluster>
              <A.notice :if={@saved} id="saved" tone="success" result title="Saved">
                {inspect(@saved)}
              </A.notice>
            </A.stack>
          </.form>
        </section>

        <section>
          <h2>Layouts</h2>
          <A.stack>
            <p class="muted">Stack: vertical rhythm.</p>
            <A.stack>
              <div class="box">First</div>
              <div class="box">Second</div>
            </A.stack>
            <p class="muted">Cluster: an inline group that wraps.</p>
            <A.cluster>
              <div :for={n <- 1..8} class="box">Item {n}</div>
            </A.cluster>
            <p class="muted">
              Grid: columns from a minimum item width. Narrow the window to see it reflow.
            </p>
            <A.grid>
              <div :for={n <- 1..6} class="box">Cell {n}</div>
            </A.grid>
            <p class="muted">Split: two regions that stack when they no longer fit.</p>
            <A.split>
              <div class="box">Main region</div>
              <:secondary>
                <div class="box">Secondary region</div>
              </:secondary>
            </A.split>
          </A.stack>
        </section>

        <section>
          <h2>Record browser</h2>
          <p class="muted">
            Search all 200 records, sort by name or score, and change pages. Selection stays available in the inspector.
          </p>
          <A.table_inspector
            id="records"
            rows={@records.rows}
            caption="Synthetic example records"
            query={@query}
            search_event="record_search"
            sort_event="record_sort"
            sort_by={@sort_by}
            sort_direction={@sort_direction}
            select_event="record_select"
            selected_id={@selected_id}
            selection_label={@selection_label}
            page={@page}
            pages={@records.pages}
            first={@records.first}
            last={@records.last}
            total={@records.total}
            page_event="record_page"
            page_size={@page_size}
            page_sizes={[10, 25, 50]}
            size_event="record_size"
          >
            <:col :let={row} label="Identifier">{row.id}</:col>
            <:col :let={row} label="Name" sort_key="name">{row.name}</:col>
            <:col :let={row} label="Score" numeric sort_key="score">{row.score}</:col>
            <:details>
              <%= if @selected do %>
                <A.record_header
                  id="selected-record"
                  title={@selected.name}
                  context={@selected.id}
                  status="Available"
                />
                <p>{@selected.group}</p>
                <p>Score: {@selected.score}</p>
                <p :if={!Enum.any?(@records.rows, &(&1.id == @selected_id))}>
                  The selected record is outside the current page or search results.
                </p>
              <% else %>
                <p>Select a record to see its details.</p>
              <% end %>
            </:details>
          </A.table_inspector>
        </section>

        <section>
          <h2>Colour tokens</h2>
          <A.grid>
            <span :for={name <- @colours} class="swatch">
              <span class="chip" style={"background: var(#{name})"}></span>
              {String.replace_prefix(name, "--armature-", "")}
            </span>
          </A.grid>
        </section>
      </div>
    </div>
    """
  end

  defp page_css, do: @page_css
end

port = String.to_integer(System.get_env("PORT", "4020"))

PhoenixPlayground.start(
  live: PreviewLive,
  port: port,
  open_browser: System.get_env("OPEN", "1") == "1"
)
