defmodule DunderMifflinBot.Repo.Migrations.CreateRankingGlobal do
  use Ecto.Migration

  def change do
    create table(:ranking_global, primary_key: false) do
      add :user_id, :bigint, primary_key: true, null: false
      add :total_incidents, :integer, default: 0, null: false
      add :total_servers, :integer, default: 0, null: false
      add :dundies_count, :integer, default: 0, null: false
      add :total_schrute_bucks_spent, :integer, default: 0, null: false
      timestamps(updated_at: false)
    end
  end
end
