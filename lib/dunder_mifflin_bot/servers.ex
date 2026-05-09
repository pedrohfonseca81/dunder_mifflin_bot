defmodule DunderMifflinBot.Servers do
  import Ecto.Query

  alias DunderMifflinBot.Repo
  alias DunderMifflinBot.Servers.Server

  def get_or_create(server_id) do
    case Repo.get(Server, server_id) do
      nil ->
        %Server{server_id: server_id}
        |> Server.changeset(%{})
        |> Repo.insert(on_conflict: :nothing, conflict_target: :server_id)
        |> case do
          {:ok, s} -> s
          _ -> Repo.get!(Server, server_id)
        end

      server ->
        server
    end
  end

  def get_language(server_id) do
    Repo.one(from s in Server, where: s.server_id == ^server_id, select: s.language) || "en"
  end

  def get_config(server_id, key, default \\ nil) do
    case Repo.get(Server, server_id) do
      nil -> default
      server -> Map.get(server.config, to_string(key), default)
    end
  end

  def set_language(server_id, locale) do
    server = get_or_create(server_id)
    server |> Server.changeset(%{language: locale}) |> Repo.update()
  end

  def set_config(server_id, key, value) do
    server = get_or_create(server_id)
    new_config = Map.put(server.config || %{}, to_string(key), value)
    server |> Server.changeset(%{config: new_config}) |> Repo.update()
  end

  def list_with_event_channel do
    from(s in Server, where: not is_nil(s.event_channel_id) and s.event_credits > 0)
    |> Repo.all()
  end

  def decrement_event_credits(server_id) do
    from(s in Server, where: s.server_id == ^server_id and s.event_credits > 0)
    |> Repo.update_all(inc: [event_credits: -1])
  end

  def add_event_credits(server_id, amount) do
    from(s in Server, where: s.server_id == ^server_id)
    |> Repo.update_all(inc: [event_credits: amount])
  end
end
