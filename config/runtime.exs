import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/transmission_manager start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :transmission_manager, TransmissionManagerWeb.Endpoint, server: true
end

if config_env() == :prod do
  # check that all required env vars are present
  expected_env_vars = [
    "TRANSMISSION_USERNAME",
    "TRANSMISSION_PASSWORD",
    "TRANSMISSION_HOST",
    "SECRET_KEY_BASE",
    "PHX_HOST",
    "PHX_SERVER",
    "MAIL_FROM_ADDRESS",
    "MAIL_TO_ADDRESS",
    "MAIL_TO_NAME",
    "POSTMARK_API_KEY",
    "RULESET"
  ]

  optional_env_vars = [
    "REFRESH_RATE",
    "CLEAN_RATE",
    "DRY_RUN",
    "SCHEME",
    "PORT"
  ]

  # parse required vars
  vars =
    expected_env_vars
    |> Enum.reduce(%{}, fn env_var, acc ->
      val =
        System.get_env(env_var) ||
          raise """
          environment variable #{env_var} is missing.
          """

      acc
      |> Map.put(env_var, val)
    end)

  # parse optional vars
  vars =
    optional_env_vars
    |> Enum.reduce(vars, fn env_var, acc ->
      val = System.get_env(env_var)

      if val do
        acc
        |> Map.put(env_var, val)
      else
        acc
      end
    end)

  #############################################################################
  # Transmission Login

  config :transmission_manager,
    credentials: %{
      username: Map.get(vars, "TRANSMISSION_USERNAME"),
      password: Map.get(vars, "TRANSMISSION_PASSWORD"),
      host: Map.get(vars, "TRANSMISSION_HOST")
    },
    refresh_rate_ms: Map.get(vars, "REFRESH_RATE", "500") |> String.to_integer(),
    clean_rate_ms: Map.get(vars, "CLEAN_RATE", "10000") |> String.to_integer(),
    dry_run: Map.get(vars, "DRY_RUN", "true") |> String.to_atom(),
    mail_from_address: Map.get(vars, "MAIL_FROM_ADDRESS"),
    mail_to_address: Map.get(vars, "MAIL_TO_ADDRESS"),
    mail_to_name: Map.get(vars, "MAIL_TO_NAME"),
    ruleset: Map.get(vars, "RULESET")

  #############################################################################
  # Swoosh Mails

  config :transmission_manager, TransmissionManager.Mailer,
    adapter: Swoosh.Adapters.Postmark,
    api_key: Map.get(vars, "POSTMARK_API_KEY")

  #############################################################################
  # Repo

  # database_url =
  #   System.get_env("DATABASE_URL") ||
  #     raise """
  #     environment variable DATABASE_URL is missing.
  #     For example: ecto://USER:PASS@HOST/DATABASE
  #     """

  # maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  # config :transmission_manager, TransmissionManager.Repo,
  #   # ssl: true,
  #   url: database_url,
  #   pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  #   socket_options: maybe_ipv6

  #############################################################################
  # HTTP Endpoint

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.

  host = Map.get(vars, "PHX_HOST")
  port = String.to_integer(Map.get(vars, "PORT"))
  scheme = Map.get(vars, "SCHEME", "http")
  secret_key_base = Map.get(vars, "SECRET_KEY_BASE")

  config :transmission_manager, TransmissionManagerWeb.Endpoint,
    url: [host: host, port: port, scheme: scheme],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end
