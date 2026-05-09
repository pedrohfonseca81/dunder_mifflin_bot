defmodule DunderMifflinBot.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DunderMifflinBot.Repo,
      {Oban, Application.fetch_env!(:dunder_mifflin_bot, Oban)},
      DunderMifflinBot.CharacterSession,
      DunderMifflinBot.Consumer,
      {Plug.Cowboy,
       scheme: :http,
       plug: DunderMifflinBot.Payments.WebhookHandler,
       options: [port: String.to_integer(System.get_env("PORT") || "4000")]}
    ]

    opts = [strategy: :one_for_one, name: DunderMifflinBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
