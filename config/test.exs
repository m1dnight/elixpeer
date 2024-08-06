import Config

#############################################################################
# Transmission Login
config :elixpeer,
  credentials: %{
    username: "transmission",
    password: "transmission",
    host: System.get_env("TRANSMISSION_TEST_HOST", "http://transmission:9091/transmission/rpc")
  },
  refresh_rate_ms: 500,
  # refresh_rate_ms: 500,
  clean_rate_ms: 10_000,
  dry_run: true,
  rules: []

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :elixpeer, Elixpeer.Repo,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  database:
    System.get_env("POSTGRES_DB") || "elixpeer_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  port: String.to_integer(System.get_env("POSTGRES_TEST_PORT") || "5432"),
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :elixpeer, ElixpeerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "MiOkxlCBJmDbS8KuQMETEbcZYjwYWWLLurxolIgh5HMk9z0I45ZVo9iguFblg4Qd",
  server: false

# In test we don't send emails
config :elixpeer, Elixpeer.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
