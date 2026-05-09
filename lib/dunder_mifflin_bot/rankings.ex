defmodule DunderMifflinBot.Rankings do
  import Ecto.Query

  alias DunderMifflinBot.Repo
  alias DunderMifflinBot.Rankings.RankingGlobal

  def get_or_create(user_id) do
    case Repo.get(RankingGlobal, user_id) do
      nil ->
        %RankingGlobal{user_id: user_id}
        |> RankingGlobal.changeset(%{})
        |> Repo.insert(on_conflict: :nothing, conflict_target: :user_id)
        |> case do
          {:ok, r} -> r
          _ -> Repo.get!(RankingGlobal, user_id)
        end

      ranking ->
        ranking
    end
  end

  def list_top(limit \\ 10) do
    from(r in RankingGlobal,
      order_by: [desc: r.total_schrute_bucks_spent],
      limit: ^limit
    )
    |> Repo.all()
  end
end
