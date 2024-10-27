# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

alias Elixpeer.Rule

#############################################################################
# Transmission Login
config :elixpeer,
  credentials: %{
    username: System.get_env("TRANSMISSION_USERNAME", "transmission"),
    password: System.get_env("TRANSMISSION_PASSWORD", "transmission"),
    host: System.get_env("TRANSMISSION_HOST", "http://localhost:9091/transmission/rpc")
  },
  refresh_rate_ms: 500,
  refresh: true,
  # refresh_rate_ms: 500,
  clean_rate_ms: 10_000,
  dry_run: true,
  rules: [],
  send_mails: true,
  mail_from_address: "from@example.com",
  mail_to_address: "to@example.com",
  mail_to_name: "Example",
  ruleset: System.get_env("RULESET", "age > 10000000000")

#############################################################################
# Repo

config :elixpeer,
  ecto_repos: [Elixpeer.Repo],
  generators: [timestamp_type: :utc_datetime]

#############################################################################
# Swoosh Mails

config :elixpeer, Elixpeer.Mailer, adapter: Swoosh.Adapters.Local

#############################################################################
# HTTP Endpoint
# Configures the endpoint
config :elixpeer, ElixpeerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: ElixpeerWeb.ErrorHTML, json: ElixpeerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Elixpeer.PubSub,
  live_view: [signing_salt: "XWsvW5eM"],
  check_origin: :conn

#############################################################################
# Mailer

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :elixpeer, Elixpeer.Mailer, adapter: Swoosh.Adapters.Local

#############################################################################
# JavaScript
# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  empty: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

#############################################################################
# CSS

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  empty: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

#############################################################################
# Logger

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger,
  compile_time_purge_matching: [
    [application: Tesla],
    [module: Tesla.Middleware.Logger, level_lower_than: :error]
  ]

config :tesla, Tesla.Middleware.Logger, debug: false, log_level: :info

#############################################################################
# Others

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
