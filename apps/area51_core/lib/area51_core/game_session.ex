defmodule Area51Core.GameSession do
  # Need Jason Encoder since this will be part of the live state
  @derive Jason.Encoder
  @type t() :: %__MODULE__{
          narrative: String.t(),
          id: integer()
        }
  defstruct [:narrative, :id]
end
