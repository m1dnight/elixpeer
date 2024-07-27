import Config

#############################################################################
# Transmission Login
config :transmission_manager,
  credentials: %{
    username: "transmission",
    password: "transmission",
    host: "http://localhost:9091/transmission/rpc"
  },
  refresh_rate_ms: 500,
  # refresh_rate_ms: 500,
  clean_rate_ms: 10_000,
  dry_run: true,
  rules: []

#############################################################################
# Repo

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
# config :transmission_manager, TransmissionManager.Repo,
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost",
#   database: "transmission_manager_test#{System.get_env("MIX_TEST_PARTITION")}",
#   pool: Ecto.Adapters.SQL.Sandbox,
#   pool_size: 10

#############################################################################
# HTTP Endpoint

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :transmission_manager, TransmissionManagerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "IeoNMycBUB7M0P34AhNAsRDeZb/wNzrb5p5agOSWNPzaohLOrxIe/cnyCq/8V1Yr",
  server: false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

#############################################################################
# Mailer

# In test we don't send emails.
config :transmission_manager, TransmissionManager.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

#############################################################################
# Logger

# Print only warnings and errors during test
config :logger, level: :warning
