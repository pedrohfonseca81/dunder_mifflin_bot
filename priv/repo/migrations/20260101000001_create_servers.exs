defmodule DunderMifflinBot.Repo.Migrations.CreateServers do
  use Ecto.Migration

  def change do
    create table(:servers, primary_key: false) do
      add :server_id, :bigint, primary_key: true, null: false
      add :language, :string, default: "en", null: false
      add :event_channel_id, :bigint
      add :event_credits, :integer, default: 0, null: false
      add :config, :jsonb, default: "{}", null: false
      timestamps(updated_at: false)
    end
  end
end
