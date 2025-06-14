import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :area51, Area51.Data.Repo,
  database: Path.expand("../area51_data_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :area51, Area51.Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "9KZlnXZUq2rf2KjJILk/+A3uwcAhnAiY+L53wlzDB9J/I8IUW/sbcuVfdtukCKcD",
  server: false

# Disable logs during test by default
config :logger, level: :none
# If we enable it,
config :logger, :console,
  format: "[$level] $message $metadata\n",
  metadata: :all

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
