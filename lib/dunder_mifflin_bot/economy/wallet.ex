defmodule DunderMifflinBot.Economy.Wallet do
  import Ecto.Query

  alias DunderMifflinBot.Repo
  alias DunderMifflinBot.Members
  alias DunderMifflinBot.Members.{Member, Transaction}

  @daily_amount 15
  @daily_cooldown_hours 24

  def balance(user_id, server_id) do
    member = Members.get_or_create(user_id, server_id)
    member.schrute_bucks
  end

  def can_afford?(user_id, server_id, cost) do
    balance(user_id, server_id) >= cost
  end

  def debit(user_id, server_id, cost, command) do
    Repo.transaction(fn ->
      member = Members.get_or_create(user_id, server_id)

      if member.schrute_bucks < cost do
        Repo.rollback(:insufficient_funds)
      end

      {1, _} =
        from(m in Member, where: m.user_id == ^user_id and m.server_id == ^server_id)
        |> Repo.update_all(inc: [schrute_bucks: -cost])

      %Transaction{}
      |> Transaction.changeset(%{
        user_id: user_id,
        server_id: server_id,
        amount: -cost,
        type: "command_use",
        command: command
      })
      |> Repo.insert!()

      member.schrute_bucks - cost
    end)
  end

  def credit(user_id, server_id, amount, type, opts \\ []) do
    Repo.transaction(fn ->
      Members.get_or_create(user_id, server_id)

      from(m in Member, where: m.user_id == ^user_id and m.server_id == ^server_id)
      |> Repo.update_all(inc: [schrute_bucks: amount])

      %Transaction{}
      |> Transaction.changeset(%{
        user_id: user_id,
        server_id: server_id,
        amount: amount,
        type: type,
        billing_id: opts[:billing_id]
      })
      |> Repo.insert!()
    end)
  end

  def claim_daily(user_id, server_id) do
    member = Members.get_or_create(user_id, server_id)
    now = DateTime.utc_now()

    cooldown_passed =
      case member.last_expediente do
        nil -> true
        last -> DateTime.diff(now, last, :hour) >= @daily_cooldown_hours
      end

    if cooldown_passed do
      Repo.transaction(fn ->
        from(m in Member, where: m.user_id == ^user_id and m.server_id == ^server_id)
        |> Repo.update_all(set: [last_expediente: now], inc: [schrute_bucks: @daily_amount])

        %Transaction{}
        |> Transaction.changeset(%{
          user_id: user_id,
          server_id: server_id,
          amount: @daily_amount,
          type: "daily"
        })
        |> Repo.insert!()

        member.schrute_bucks + @daily_amount
      end)
    else
      next = DateTime.add(member.last_expediente, @daily_cooldown_hours, :hour)
      {:error, {:already_claimed, next}}
    end
  end

  def transfer(from_user_id, to_user_id, server_id, amount) when amount > 0 do
    Repo.transaction(fn ->
      from_member = Members.get_or_create(from_user_id, server_id)
      Members.get_or_create(to_user_id, server_id)

      if from_member.schrute_bucks < amount do
        Repo.rollback(:insufficient_funds)
      end

      from(m in Member, where: m.user_id == ^from_user_id and m.server_id == ^server_id)
      |> Repo.update_all(inc: [schrute_bucks: -amount])

      from(m in Member, where: m.user_id == ^to_user_id and m.server_id == ^server_id)
      |> Repo.update_all(inc: [schrute_bucks: amount])

      %Transaction{}
      |> Transaction.changeset(%{
        user_id: from_user_id,
        server_id: server_id,
        amount: -amount,
        type: "transfer"
      })
      |> Repo.insert!()

      %Transaction{}
      |> Transaction.changeset(%{
        user_id: to_user_id,
        server_id: server_id,
        amount: amount,
        type: "transfer"
      })
      |> Repo.insert!()

      %{sender_balance: from_member.schrute_bucks - amount}
    end)
  end
end
