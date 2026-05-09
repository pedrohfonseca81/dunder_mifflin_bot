defmodule DunderMifflinBot.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members, primary_key: false) do
      add :user_id, :bigint, null: false
      add :server_id, :bigint, null: false
      add :schrute_bucks, :integer, default: 100, null: false
      add :last_expediente, :utc_datetime
      add :dundies, :jsonb, default: "{}", null: false
      add :warns_count, :integer, default: 0, null: false
      add :is_investor, :boolean, default: false, null: false
      timestamps(updated_at: false)
    end

    execute "ALTER TABLE members ADD PRIMARY KEY (user_id, server_id)"
    create index(:members, [:server_id])
  end
end
