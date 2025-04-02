defmodule Area51Data.Repo do
  use Ecto.Repo,
    otp_app: :area51_data,
    adapter: Ecto.Adapters.SQLite3
end
