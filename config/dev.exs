import Config

config :dunder_mifflin_bot, DunderMifflinBot.Repo,
  url: System.get_env("DATABASE_URL") || "postgresql://postgres:postgres@localhost:54322/postgres",
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :logger, :console,
  format: "[$level] $message\n",
  level: :debug
