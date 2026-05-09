defmodule DunderMifflinBot.Repo do
  use Ecto.Repo,
    otp_app: :dunder_mifflin_bot,
    adapter: Ecto.Adapters.Postgres
end
