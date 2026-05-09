defmodule DunderMifflinBot.Repo.Migrations.CreateMeetings do
  use Ecto.Migration

  def change do
    create table(:meetings, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :server_id, :bigint, null: false
      add :channel_id, :bigint, null: false
      add :caller_user_id, :bigint, null: false
      add :target_user_id, :bigint, null: false
      add :topic, :text, null: false
      add :messages, :jsonb, default: "[]"
      add :status, :string, default: "active", null: false
      timestamps(updated_at: false)
    end

    create index(:meetings, [:server_id])
  end
end
