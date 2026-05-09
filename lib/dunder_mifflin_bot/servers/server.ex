defmodule DunderMifflinBot.Servers.Server do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:server_id, :integer, autogenerate: false}
  schema "servers" do
    field :language, :string, default: "en"
    field :event_channel_id, :integer
    field :event_credits, :integer, default: 0
    field :config, :map, default: %{}
    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(server, attrs) do
    server
    |> cast(attrs, [:server_id, :language, :event_channel_id, :event_credits, :config])
    |> validate_required([:server_id])
  end
end
