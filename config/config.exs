import Config

config :dunder_mifflin_bot, ecto_repos: [DunderMifflinBot.Repo]

config :dunder_mifflin_bot, DunderMifflinBot.Repo,
  database: "dunder_mifflin_bot_#{config_env()}",
  pool_size: 10

config :dunder_mifflin_bot, Oban,
  repo: DunderMifflinBot.Repo,
  queues: [
    events: 5,
    meetings: 10,
    reminders: 5,
    payments: 3
  ],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"*/30 * * * *", DunderMifflinBot.Workers.EventWorker,
        args: %{"type" => "scheduled_check"}},
       {"* * * * *", DunderMifflinBot.Workers.EventWorker,
        args: %{"type" => "shift_end_check"}},
       {"0 9 * * *", DunderMifflinBot.Workers.EventWorker,
        args: %{"type" => "birthday_check"}}
     ]}
  ]

config :nostrum,
  token: System.get_env("DISCORD_TOKEN"),
  gateway_intents: [
    :guilds,
    :guild_members,
    :guild_messages,
    :message_content,
    :guild_message_reactions,
    :direct_messages
  ]

config :dunder_mifflin_bot, DunderMifflinBot.Gettext, default_locale: "en"

import_config "#{config_env()}.exs"
