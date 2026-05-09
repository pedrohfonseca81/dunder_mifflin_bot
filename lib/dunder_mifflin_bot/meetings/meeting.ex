defmodule DunderMifflinBot.Meetings.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "meetings" do
    field :server_id, :integer
    field :channel_id, :integer
    field :caller_user_id, :integer
    field :target_user_id, :integer
    field :topic, :string
    field :messages, {:array, :map}, default: []
    field :status, :string, default: "active"
    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(meeting, attrs) do
    meeting
    |> cast(attrs, [:server_id, :channel_id, :caller_user_id, :target_user_id,
                    :topic, :messages, :status])
    |> validate_required([:server_id, :channel_id, :caller_user_id, :target_user_id, :topic])
    |> validate_inclusion(:status, ["active", "completed", "timeout"])
  end
end
