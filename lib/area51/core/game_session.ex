defmodule Area51.Core.GameSession do
  @moduledoc """
  Represents a game session in the core domain of the application.

  This struct holds essential information about a game session, including its
  `id`, `title`, `description`, and the ongoing `narrative`.
  It derives `Jason.Encoder` for serialization.
  """
  # Need Jason Encoder since this will be part of the live state
  @derive Jason.Encoder
  @type t() :: %__MODULE__{
          narrative: String.t(),
          id: integer(),
          title: String.t(),
          description: String.t()
        }
  defstruct [:narrative, :id, :title, :description]
end
