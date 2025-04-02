defmodule Area51.Repo do
  use Ecto.Repo,
    otp_app: :area51,
    adapter: Ecto.Adapters.SQLite3
end
