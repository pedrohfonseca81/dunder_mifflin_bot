defmodule DunderMifflinBot.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_types ~w(meeting pretzel_day twss birthday end_shift)

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "events" do
    field :server_id, :integer
    field :type, :string
    field :content, :string
    field :mentioned_users, {:array, :integer}, default: []
    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:server_id, :type, :content, :mentioned_users])
    |> validate_required([:server_id, :type, :content])
    |> validate_inclusion(:type, @valid_types)
  end
end
