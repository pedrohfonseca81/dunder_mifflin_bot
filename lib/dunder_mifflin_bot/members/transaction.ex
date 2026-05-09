defmodule DunderMifflinBot.Members.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_types ~w(daily purchase command_use transfer donation admin_grant)

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "transactions" do
    field :user_id, :integer
    field :server_id, :integer
    field :amount, :integer
    field :type, :string
    field :command, :string
    field :billing_id, :string
    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(tx, attrs) do
    tx
    |> cast(attrs, [:user_id, :server_id, :amount, :type, :command, :billing_id])
    |> validate_required([:user_id, :server_id, :amount, :type])
    |> validate_inclusion(:type, @valid_types)
  end
end
