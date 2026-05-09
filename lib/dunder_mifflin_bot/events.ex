defmodule DunderMifflinBot.Events do
  import Ecto.Query

  alias DunderMifflinBot.Repo
  alias DunderMifflinBot.Events.Event

  def log_event(attrs) do
    %Event{} |> Event.changeset(attrs) |> Repo.insert()
  end

  def count_twss_today(server_id) do
    today = Date.utc_today()

    from(e in Event,
      where:
        e.server_id == ^server_id and
          e.type == "twss" and
          fragment("DATE(?)", e.inserted_at) == ^today,
      select: count(e.id)
    )
    |> Repo.one() || 0
  end
end
