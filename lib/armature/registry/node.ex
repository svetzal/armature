defmodule Armature.Registry.Node do
  @moduledoc "A function component's identity, purpose, level and declared dependencies."
  @enforce_keys [:id, :level, :module, :function, :purpose]
  defstruct [:id, :level, :module, :function, :purpose, uses: []]

  @type t :: %__MODULE__{
          id: atom(),
          level: Armature.Registry.level(),
          module: module(),
          function: atom(),
          purpose: String.t(),
          uses: [atom()]
        }
end
