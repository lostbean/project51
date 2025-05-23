defmodule Area51.Core.GameState do
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
