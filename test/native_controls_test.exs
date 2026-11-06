defmodule Armature.NativeControlsTest do
  @moduledoc """
  Holds the baseline to its composition rule: molecules, organisms and templates
  render native controls through atoms, so the registry's graph tells the truth.

  This guards this repository only. A consumer's own components may write raw
  elements, so it is not a public registry check.

  Two raw elements stay, on purpose:

    * the hidden companion to the checkbox in `field/1`, which is a form value
      rather than a control, so it has no atom and is allowed by `type="hidden"`;
    * the wrapping `<label>` in `theme_choice/1`, which is the choice's hit-target
      container. It carries no `for`, so the pattern does not match it.
  """
  use ExUnit.Case, async: true

  @raw_control ~r/<(?:button|select|textarea|a)\b|<label\b[^>]*\sfor=|<input\b[^>]*/
  @hidden_input ~r/^<input\s+type="hidden"/

  for level <- ~w(molecules organisms templates) do
    path = "lib/armature/components/#{level}.ex"
    @external_resource path

    test "#{level} render native controls only through atoms" do
      assert raw_control_lines(File.read!(unquote(path))) == []
    end
  end

  defp raw_control_lines(source) do
    @raw_control
    |> Regex.scan(source, return: :index)
    |> Enum.map(fn [{start, length}] -> {start, binary_part(source, start, length)} end)
    |> Enum.reject(fn {_start, element} -> element =~ @hidden_input end)
    |> Enum.map(fn {start, _element} -> line_number(source, start) end)
  end

  defp line_number(source, offset) do
    source
    |> binary_part(0, offset)
    |> String.split("\n")
    |> length()
  end
end
