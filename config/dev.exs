import Config

#############################################################################
# Transmission Login
config :transmission_manager,
  refresh_rate_ms: 500,
  # refresh_rate_ms: 500,
  clean_rate_ms: 10_000000,
  dry_run: true,
  rules: [],
  dev_routes: true,
  mail_from_address: "from@example.com",
  mail_to_address: "to@example.com",
  mail_to_name: "Example"

#############################################################################
# Repo

# Configure your database
config :transmission_manager, TransmissionManager.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "transmission_manager_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

#############################################################################
# Swoosh Mails

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false
config :transmission_manager, TransmissionManager.Mailer, adapter: Swoosh.Adapters.Local

#############################################################################
# HTTP Endpoint

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :transmission_manager, TransmissionManagerWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "jcpqD5Yghhb7oyNYHekSeSCTZ2N4SAPX0LBVtLgTtxJADnzd73RWmN2fD9LnnpiW",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/transmission_manager_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

#############################################################################
# Logger

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Enable dev routes for dashboard and mailbox
config :transmission_manager, dev_routes: true

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Include HEEx debug annotations as HTML comments in rendered markup
config :phoenix_live_view, :debug_heex_annotations, true
