defmodule Area51Core.Clue do
  # Need Jason Encoder since this will be part of the live state
  @derive Jason.Encoder
  @type t() :: %__MODULE__{
          content: String.t()
        }
  defstruct content: nil
end
