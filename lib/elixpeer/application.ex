defmodule Elixpeer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  @spec start(any(), any()) :: {:error, any()} | {:ok, pid()}
  def start(_type, _args) do
    children = [
      Elixpeer.Repo,
      ElixpeerWeb.Telemetry,
      # Elixpeer.Repo,
      {DNSCluster, query: Application.get_env(:elixpeer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Elixpeer.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Elixpeer.Finch},
      # Start a worker by calling: Elixpeer.Worker.start_link(arg)
      # {Elixpeer.Worker, arg},
      %{
        id: Transmission,
        start: {Transmission, :start_link, transmission_arguments()}
      },
      %{
        id: Elixpeer.TransmissionConnection,
        start:
          {Elixpeer.TransmissionConnection, :start_link,
           [[], [name: Elixpeer.TransmissionConnection]]}
      },
      ElixpeerWeb.Endpoint,
      Elixpeer.Cleaner.Worker
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: Elixpeer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixpeerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # returns the arguments to connect to transmission
  @spec transmission_arguments() :: [String.t()]
  defp transmission_arguments do
    credentials = Application.get_env(:elixpeer, :credentials, %{})

    args = [
      credentials.host,
      credentials.username,
      credentials.password
    ]

    args
    |> Enum.each(fn arg ->
      case arg do
        nil -> raise "Missing transmission argument"
        "" -> raise "Missing transmission argument"
        _ -> arg
      end
    end)

    args
  end
end
