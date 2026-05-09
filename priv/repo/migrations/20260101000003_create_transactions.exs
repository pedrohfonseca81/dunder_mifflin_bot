defmodule DunderMifflinBot.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :user_id, :bigint, null: false
      add :server_id, :bigint, null: false
      add :amount, :integer, null: false
      add :type, :string, null: false
      add :command, :string
      add :billing_id, :string
      timestamps(updated_at: false)
    end

    create index(:transactions, [:user_id, :server_id])
    create index(:transactions, [:billing_id])
  end
end
