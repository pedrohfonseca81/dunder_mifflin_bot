defmodule DunderMifflinBot.Meetings do
  alias DunderMifflinBot.Repo
  alias DunderMifflinBot.Meetings.Meeting

  def create_meeting(attrs) do
    %Meeting{} |> Meeting.changeset(attrs) |> Repo.insert()
  end

  def get_meeting(id), do: Repo.get(Meeting, id)
  def get_meeting!(id), do: Repo.get!(Meeting, id)

  def update_status(id, status) do
    case Repo.get(Meeting, id) do
      nil -> {:error, :not_found}
      meeting -> meeting |> Meeting.changeset(%{status: status}) |> Repo.update()
    end
  end

  def append_message(id, message) do
    case Repo.get(Meeting, id) do
      nil -> {:error, :not_found}
      meeting ->
        meeting
        |> Meeting.changeset(%{messages: meeting.messages ++ [message]})
        |> Repo.update()
    end
  end
end
