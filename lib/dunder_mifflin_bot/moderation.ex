defmodule DunderMifflinBot.Moderation do
  import Ecto.Query

  alias DunderMifflinBot.Repo
  alias DunderMifflinBot.Moderation.Incident

  def log_incident(attrs) do
    %Incident{} |> Incident.changeset(attrs) |> Repo.insert()
  end

  def list_for_server(server_id, limit \\ 20) do
    from(i in Incident,
      where: i.server_id == ^server_id,
      order_by: [desc: i.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def list_for_member(user_id, server_id) do
    from(i in Incident,
      where: i.target_user_id == ^user_id and i.server_id == ^server_id,
      order_by: [desc: i.inserted_at]
    )
    |> Repo.all()
  end

  def count_trials(user_id, server_id) do
    from(i in Incident,
      where: i.target_user_id == ^user_id and i.server_id == ^server_id and i.type == "trial",
      select: count(i.id)
    )
    |> Repo.one() || 0
  end
end
