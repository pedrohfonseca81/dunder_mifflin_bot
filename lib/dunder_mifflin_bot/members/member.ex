defmodule DunderMifflinBot.Members.Member do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "members" do
    field :user_id, :integer, primary_key: true
    field :server_id, :integer, primary_key: true
    field :schrute_bucks, :integer, default: 100
    field :last_expediente, :utc_datetime
    field :dundies, :map, default: %{}
    field :warns_count, :integer, default: 0
    field :is_investor, :boolean, default: false
    field :birthday, :string
    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(member, attrs) do
    member
    |> cast(attrs, [:user_id, :server_id, :schrute_bucks, :last_expediente,
                    :dundies, :warns_count, :is_investor, :birthday])
    |> validate_required([:user_id, :server_id])
    |> validate_number(:schrute_bucks, greater_than_or_equal_to: 0)
  end
end
