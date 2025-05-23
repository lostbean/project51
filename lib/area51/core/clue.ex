defmodule Area51.Core.Clue do
  @moduledoc """
  Represents a clue within the core domain of the application.

  This struct simply holds the `content` of a discovered clue and
  derives `Jason.Encoder` for serialization.
  """
  # Need Jason Encoder since this will be part of the live state
  @derive Jason.Encoder
  @type t() :: %__MODULE__{
          content: String.t()
        }
  defstruct content: nil
end
