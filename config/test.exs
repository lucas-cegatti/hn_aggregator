import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hn_aggregator, HnAggregatorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Bble33Yx9zBu8l03k01ApCFblARJIkmNHw4wnNxAQQQobumHMSmcUi4THLq47ueN",
  server: false

# In test we don't send emails.
config :hn_aggregator, HnAggregator.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
