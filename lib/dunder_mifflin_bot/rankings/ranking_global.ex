defmodule DunderMifflinBot.Rankings.RankingGlobal do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:user_id, :integer, autogenerate: false}
  schema "ranking_global" do
    field :total_incidents, :integer, default: 0
    field :total_servers, :integer, default: 0
    field :dundies_count, :integer, default: 0
    field :total_schrute_bucks_spent, :integer, default: 0
    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(r, attrs) do
    r
    |> cast(attrs, [:user_id, :total_incidents, :total_servers, :dundies_count,
                    :total_schrute_bucks_spent])
    |> validate_required([:user_id])
  end
end
