defmodule DunderMifflinBot.Moderation.Incident do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_types ~w(warn mute timeout kick ban trial)

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "incidents" do
    field :server_id, :integer
    field :type, :string
    field :target_user_id, :integer
    field :author_user_id, :integer
    field :reason, :string
    field :ai_response, :string
    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [:server_id, :type, :target_user_id, :author_user_id, :reason, :ai_response])
    |> validate_required([:server_id, :type, :target_user_id, :author_user_id])
    |> validate_inclusion(:type, @valid_types)
  end
end
