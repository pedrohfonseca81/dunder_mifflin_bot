import Config

owners_ids =
  System.get_env("OWNERS_ID", "")
  |> String.split([",", ";", " "], trim: true)
  |> Enum.flat_map(fn raw_id ->
    case Integer.parse(raw_id) do
      {id, ""} -> [id]
      _ -> []
    end
  end)

if config_env() in [:dev, :test] do
  if Code.ensure_loaded?(Dotenvy) do
    Dotenvy.source!([".env", System.get_env()])
    |> Enum.each(fn {k, v} -> System.put_env(k, v) end)
  end
end

if config_env() == :dev do
  config :dunder_mifflin_bot, DunderMifflinBot.Repo,
    url: System.get_env("DATABASE_URL") || "postgresql://postgres:postgres@localhost:54322/postgres",
    pool_size: 5,
    ssl: [verify: :verify_none],
    socket_options: [:inet6]
end

if config_env() == :prod do
  config :dunder_mifflin_bot, DunderMifflinBot.Repo,
    url: System.get_env("DATABASE_URL") || raise("DATABASE_URL missing"),
    ssl: [verify: :verify_none],
    prepare: :unnamed,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: [:inet6]
end

config :nostrum,
  token: System.get_env("DISCORD_TOKEN") || raise("DISCORD_TOKEN missing")

config :dunder_mifflin_bot,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  abacatepay_api_key: System.get_env("ABACATEPAY_API_KEY"),
  webhook_secret: System.get_env("WEBHOOK_SECRET"),
  discord_application_id: System.get_env("DISCORD_APPLICATION_ID"),
  owners_ids: owners_ids
