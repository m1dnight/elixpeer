defmodule TransmissionManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TransmissionManagerWeb.Telemetry,
      # TransmissionManager.Repo,
      {DNSCluster,
       query: Application.get_env(:transmission_manager, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TransmissionManager.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TransmissionManager.Finch},
      # Start a worker by calling: TransmissionManager.Worker.start_link(arg)
      # {TransmissionManager.Worker, arg},
      # Start to serve requests, typically the last entry
      TransmissionManagerWeb.Endpoint,
      %{
        id: TransmissionManager.TransmissionConnection,
        start:
          {TransmissionManager.TransmissionConnection, :start_link,
           [[], [name: TransmissionManager.TransmissionConnection]]}
      },
      TransmissionManager.Cleaner.Worker
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TransmissionManager.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TransmissionManagerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
