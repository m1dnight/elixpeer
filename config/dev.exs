import Config

#############################################################################
# Transmission Login
config :elixpeer,
  refresh_rate_ms: 1000,
  refresh: false,
  clean_rate_ms: 10_000,
  dry_run: true,
  rules: [],
  dev_routes: true,
  mail_from_address: "christophe@call-cc.be",
  mail_to_address: "christophe.detroyer@gmail.com",
  mail_to_name: "Jos De Bosduif",
  ruleset: "tracker !~= /flacsfor.me/ and ((age > 10 and ratio > 7 and age > 40) or (age > 60))"

#############################################################################
# Repo

# Configure your database
config :elixpeer, Elixpeer.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "elixpeer",
  port: 5432,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  # log: false,
  pool_size: 10

#############################################################################
# Swoosh Mails

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

config :elixpeer, Elixpeer.Mailer,
  adapter: Swoosh.Adapters.Postmark,
  api_key: "6d53d319-f3a9-48d2-8bfc-508d866612ca"

#############################################################################
# HTTP Endpoint

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :elixpeer, ElixpeerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "1f1wQ4FadbQQ0ZXKrhcL06krXyc2ahIKm1+TeE4cMo/xpBgaO39oDgAgngfQkeXS",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:empty, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:empty, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/elixpeer_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

#############################################################################
# Logger

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Enable dev routes for dashboard and mailbox
config :elixpeer, dev_routes: true

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Include HEEx debug annotations as HTML comments in rendered markup
config :phoenix_live_view, :debug_heex_annotations, true
