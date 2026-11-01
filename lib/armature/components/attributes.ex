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
      {:size_event, :string, [default: nil]}
    ]
  end
end
