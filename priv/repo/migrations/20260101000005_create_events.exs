defmodule DunderMifflinBot.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :server_id, :bigint, null: false
      add :type, :string, null: false
      add :content, :text, null: false
      add :mentioned_users, {:array, :bigint}, default: []
      timestamps(updated_at: false)
    end

    create index(:events, [:server_id])
  end
end
