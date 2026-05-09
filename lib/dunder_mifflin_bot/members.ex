defmodule DunderMifflinBot.Members do
  import Ecto.Query

  alias DunderMifflinBot.Repo
  alias DunderMifflinBot.Members.Member

  def get_or_create(user_id, server_id) do
    case Repo.get_by(Member, user_id: user_id, server_id: server_id) do
      nil ->
        %Member{}
        |> Member.changeset(%{user_id: user_id, server_id: server_id, schrute_bucks: 100})
        |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :server_id])
        |> case do
          {:ok, m} -> m
          _ -> Repo.get_by!(Member, user_id: user_id, server_id: server_id)
        end

      member ->
        member
    end
  end

  def increment_warns(user_id, server_id) do
    from(m in Member, where: m.user_id == ^user_id and m.server_id == ^server_id)
    |> Repo.update_all(inc: [warns_count: 1])
  end

  def set_birthday(user_id, server_id, birthday) do
    get_or_create(user_id, server_id)
    |> Member.changeset(%{birthday: birthday})
    |> Repo.update()
  end

  def set_investor(user_id, server_id) do
    get_or_create(user_id, server_id)
    |> Member.changeset(%{is_investor: true})
    |> Repo.update()
  end

  def add_dundie(user_id, server_id, category) do
    member = get_or_create(user_id, server_id)
    dundies = Map.put(member.dundies, category, DateTime.utc_now() |> DateTime.to_string())
    member |> Member.changeset(%{dundies: dundies}) |> Repo.update()
  end

  def list_with_birthday_today(server_id) do
    today_str = Date.utc_today() |> Calendar.strftime("%m-%d")

    from(m in Member, where: m.server_id == ^server_id and m.birthday == ^today_str)
    |> Repo.all()
  end

  def list_top_by_balance(server_id, limit \\ 5) do
    from(m in Member,
      where: m.server_id == ^server_id,
      order_by: [desc: m.schrute_bucks],
      limit: ^limit
    )
    |> Repo.all()
  end

  def get_most_warned(server_id) do
    from(m in Member,
      where: m.server_id == ^server_id,
      order_by: [desc: m.warns_count],
      limit: 1
    )
    |> Repo.one()
  end
end
