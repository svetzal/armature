defmodule Armature.Components.Attributes do
  @moduledoc false
  # Attribute lists that more than one level declares. They live here, rather
  # than in a level module, so `use Armature.Components` imports only components.

  @input ~w(accept autocomplete capture checked disabled form list max maxlength min minlength multiple pattern placeholder readonly required size step)
  @select ~w(autocomplete disabled form required size)
  @textarea ~w(autocomplete cols disabled form maxlength minlength placeholder readonly required rows wrap)

  @doc "The tones a status or notice accepts."
  def tones, do: ~w(neutral success warning error)

  @doc "Global attributes `input/1` forwards to its native element."
  def input, do: @input

  @doc "Global attributes `select/1` forwards to its native element."
  def select, do: @select

  @doc "Global attributes `textarea/1` forwards to its native element."
  def textarea, do: @textarea

  @doc "Every attribute the native controls forward, for `field/1`, which wraps them."
  def controls, do: Enum.uniq(@input ++ @select ++ @textarea)

  @doc "The `col` slot attributes of `data_table/1`, which `table_inspector/1` forwards."
  def columns do
    [
      {:label, :string, [required: true]},
      {:numeric, :boolean, []},
      {:sort_key, :string, []},
      {:row_label, :boolean, []},
      {:interactive, :boolean, []}
    ]
  end

  @doc "The page-state attributes of `pagination/1`, which `table_inspector/1` forwards."
  def paging do
    [
      {:page, :integer, [required: true]},
      {:pages, :integer, [required: true]},
      {:first, :integer, [required: true]},
      {:last, :integer, [required: true]},
      {:total, :integer, [required: true]},
      {:page_event, :string, [required: true]},
      {:page_size, :integer, [default: 25]},
      {:page_sizes, :list, [default: []]},
      {:size_event, :string, [default: nil]},
      {:label, :string, [default: "Table pages"]},
      {:previous_label, :string, [default: "Previous"]},
      {:next_label, :string, [default: "Next"]},
      {:page_size_label, :string, [default: "Records per page"]},
      {:range_label, :any, [default: nil]}
    ]
  end

  @doc "The word and query attributes of `table_toolbar/1`, which `table_inspector/1` forwards."
  def toolbar do
    [
      {:search_label, :string, [default: "Search records"]},
      {:clear_label, :string, [default: "Clear search"]},
      {:count_label, :any, [default: nil]},
      {:query, :string, [default: ""]}
    ]
  end

  @doc "The density and ordering attributes of `data_table/1`, which `table_inspector/1` forwards."
  def ordering do
    [
      {:density, :string, [default: "default", values: ~w(default compact)]},
      {:sort_by, :string, [default: nil]},
      {:sort_direction, :string, [default: "asc", values: ~w(asc desc)]},
      {:sort_label, :any, [default: nil]}
    ]
  end

  @doc "The native `type` values `button/1` and `icon_button/1` accept."
  def button_types, do: ~w(button submit reset)

  @doc "The treatments `button/1` and `icon_button/1` accept."
  def button_variants, do: ~w(primary secondary)
end
