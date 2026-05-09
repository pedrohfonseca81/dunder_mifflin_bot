defmodule DunderMifflinBot.Repo.Migrations.CreateIncidents do
  use Ecto.Migration

  def change do
    create table(:incidents, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :server_id, :bigint, null: false
      add :type, :string, null: false
      add :target_user_id, :bigint, null: false
      add :author_user_id, :bigint, null: false
      add :reason, :text
      add :ai_response, :text
      timestamps(updated_at: false)
    end

    create index(:incidents, [:server_id])
    create index(:incidents, [:target_user_id, :server_id])
  end
end
