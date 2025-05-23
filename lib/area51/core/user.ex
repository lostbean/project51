defmodule Area51.Core.User do
  @moduledoc """
  Represents a user in the core domain of the application.

  This struct holds basic user information such as their external ID,
  username, and email. It derives `Jason.Encoder` for serialization.
  """
  # Need Jason Encoder since this will be part of the live state
  @derive Jason.Encoder
  @type t() :: %__MODULE__{
          external_id: String.t(),
          username: String.t(),
          email: String.t()
        }
  defstruct external_id: nil, username: nil, email: nil
end
