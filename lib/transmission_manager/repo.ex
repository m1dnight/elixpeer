defmodule TransmissionManager.Repo do
  use Ecto.Repo,
    otp_app: :transmission_manager,
    adapter: Ecto.Adapters.Postgres
end
