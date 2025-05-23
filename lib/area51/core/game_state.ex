defmodule Area51.Core.GameState do
  @moduledoc """
  Represents the state of an active game session from a specific user's perspective.

  This struct holds the current `GameSession` details, the `user_id` and
  `username` of the player, and a list of `clues` they have discovered.
  It derives `Jason.Encoder` for serialization, likely for use in live state.
  """
  # Need Jason Encoder since this will be part of the live state
  @derive Jason.Encoder
  @type t() :: %__MODULE__{
          game_session: Area51.Core.GameSession.t(),
          user_id: integer(),
          username: String.t(),
          clues: list(String.t())
        }
  defstruct user_id: nil, game_session: %Area51.Core.GameSession{}, username: nil, clues: []
end
