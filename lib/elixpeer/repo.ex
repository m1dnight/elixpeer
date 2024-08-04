defmodule Elixpeer.Repo do
  use Ecto.Repo,
    otp_app: :elixpeer,
    adapter: Ecto.Adapters.Postgres
end
