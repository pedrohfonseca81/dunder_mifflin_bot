defmodule DunderMifflinBot.Repo.Migrations.AddBirthdayToMembers do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :birthday, :string
    end

    create index(:members, [:birthday])
  end
end
