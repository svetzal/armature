defmodule Armature.Components do
  @moduledoc """
  Entry point for the accessible baseline components, one module per level:

    * `Armature.Components.Atoms`
    * `Armature.Components.Layouts`
    * `Armature.Components.Molecules`
    * `Armature.Components.Organisms`
    * `Armature.Components.Templates`

  `use Armature.Components` in consumer HTML helpers imports all five. Follow it
  with `import Phoenix.Component, except: [link: 1]` to exclude Phoenix's link.
  Styling comes from `priv/static/armature.css` and the consumer's token values.
  Give standalone controls a visible label or an accessible name;
  `Armature.Components.Molecules.field/1` supplies a label and validation
  relationships for form controls.
  """

  @themes ~w(auto light dark)

  @doc "Imports the baseline component modules of every level."
  defmacro __using__(_options) do
    quote do
      import Armature.Components.Atoms
      import Armature.Components.Layouts
      import Armature.Components.Molecules
      import Armature.Components.Organisms
      import Armature.Components.Templates
    end
  end

  @doc """
  The themes `Armature.Components.Molecules.theme_switch/1` offers and sends,
  in order. Use it to validate the event value.
  """
  @spec themes() :: [String.t()]
  def themes, do: @themes

  @doc """
  The `data-armature-theme` value for a theme chosen with
  `Armature.Components.Molecules.theme_switch/1`.

  Returns `nil` for `"auto"`: the consumer then omits `data-armature-theme`, so
  its root tokens and the system preference apply. Other themes return themselves.
  """
  @spec theme_attribute(String.t()) :: String.t() | nil
  def theme_attribute("auto"), do: nil
  def theme_attribute(theme), do: theme
end
