defmodule Area51.Core.User do
  # Need Jason Encoder since this will be part of the live state
  @derive Jason.Encoder
  @type t() :: %__MODULE__{
          external_id: String.t(),
          username: String.t(),
          email: String.t()
        }
  defstruct external_id: nil, username: nil, email: nil
end
