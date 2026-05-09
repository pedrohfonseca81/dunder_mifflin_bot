defmodule DunderMifflinBot.Commands.Economy do
  use Gettext, backend: DunderMifflinBot.Gettext

  alias DunderMifflinBot.Economy.{Wallet, Store}
  alias DunderMifflinBot.{Members, Moderation}
  alias DunderMifflinBot.Commands.Router
  alias DunderMifflinBot.Characters.{Dwight, Michael}

  @dwight_shift_lines [
    "Clocked in. 15 Schrute Bucks deposited. No overtime. No complaints.",
    "Work registered. You earned your pay. Do not make it a habit of arriving at this exact second.",
    "Shift logged. 15 SB credited. I expect the same level of performance tomorrow. Or better.",
    "Employee attendance confirmed. Schrute Bucks distributed. Report to your station.",
    "You showed up. Barely acceptable. Here are your 15 SB. This is not a celebration."
  ]

  @dwight_store_lines [
    "Welcome to the Schrute Buck Exchange. Select your denomination. These are non-refundable.",
    "I have authorized a limited selection of packages. Choose wisely. Schrute Bucks retain their value.",
    "The Schrute Buck. Legal tender. Backed by beet farm equity. Select your investment.",
    "I designed these packages myself. Each one is a sound financial decision. Pick one."
  ]

  @dwight_profile_lines [
    "Employee file review initiating. I have memorized every detail in this record.",
    "I keep detailed files on all employees. Here is what the record shows.",
    "Personnel dossier retrieved. I update these weekly. Sometimes daily."
  ]

  def handle_shift(interaction, _locale) do
    user_id = interaction.member.user_id
    server_id = interaction.guild_id

    case Wallet.claim_daily(user_id, server_id) do
      {:ok, new_balance} ->
        Router.defer_ephemeral(interaction)
        line = Enum.random(@dwight_shift_lines) <> " Balance: **#{new_balance} SB**."
        Router.send_as_character(interaction.channel_id, Dwight, line)
        Router.delete_response(interaction)

      {:error, {:already_claimed, next_time}} ->
        hours = DateTime.diff(next_time, DateTime.utc_now(), :hour)
        Router.reply_ephemeral(interaction, dgettext("economy", "shift_already_claimed", hours: hours))
    end
  end

  def handle_balance(interaction, _locale) do
    user_id = interaction.member.user_id
    server_id = interaction.guild_id
    balance = Wallet.balance(user_id, server_id)

    kevin_lines = [
      "You have... **#{balance} SB**. That is... a number. A good number? Maybe.",
      "**#{balance} Schrute Bucks**. I counted. Twice. Also I had a pretzel.",
      "Balance check: **#{balance} SB**. Kevin has spoken."
    ]

    Router.reply_ephemeral(interaction, Enum.random(kevin_lines))
  end

  def handle_pay(interaction, target_id, amount, _locale) do
    from_id = interaction.member.user_id
    server_id = interaction.guild_id

    case Wallet.transfer(from_id, target_id, server_id, amount) do
      {:ok, %{sender_balance: sender_bal}} ->
        michael_lines = [
          "Done! I transferred **#{amount} SB** to <@#{target_id}>. That is what generous people do. Like me. Your balance: **#{sender_bal} SB**.",
          "Money transferred! **#{amount} SB** to <@#{target_id}>. World's best boss doesn't just say it — he acts on it. Balance: **#{sender_bal} SB**.",
          "Transaction complete. **#{amount} SB** sent to <@#{target_id}>. You are welcome, everyone. Balance: **#{sender_bal} SB**."
        ]
        Router.reply_ephemeral(interaction, Enum.random(michael_lines))

      {:error, :insufficient_funds} ->
        Router.reply_ephemeral(interaction, dgettext("economy", "transfer_insufficient"))
    end
  end

  def handle_store(interaction, _locale) do
    packs = Store.sb_packs()

    components = [
      %{
        type: 1,
        components: Enum.map(packs, fn pack ->
          %{type: 2, style: 1, label: pack.label, custom_id: "store_#{pack.id}"}
        end)
      }
    ]

    Router.defer_ephemeral(interaction)
    content = "📦 **Schrute Bucks Store**\n#{Enum.random(@dwight_store_lines)}"
    Router.send_as_character(interaction.channel_id, Dwight, content, %{components: components})
    Router.delete_response(interaction)
  end

  def handle_profile(interaction, target_id, _locale) do
    server_id = interaction.guild_id
    member = Members.get_or_create(target_id, server_id)
    trial_count = Moderation.count_trials(target_id, server_id)

    threat = calculate_threat(member.warns_count)
    investor_badge = if member.is_investor, do: " 💼 Investor", else: ""
    dundie_count = map_size(member.dundies)

    content = """
    #{Enum.random(@dwight_profile_lines)}

    **Employee:** <@#{target_id}>#{investor_badge}
    **Schrute Bucks:** #{member.schrute_bucks} SB
    **Warnings:** #{member.warns_count} | **Trials:** #{trial_count} | **Dundies:** #{dundie_count}
    **Threat Level:** #{threat}
    """

    Router.defer_ephemeral(interaction)
    Router.send_as_character(interaction.channel_id, Dwight, content)
    Router.delete_response(interaction)
  end

  def handle_dashboard(interaction, locale) do
    server_id = interaction.guild_id
    top_members = Members.list_top_by_balance(server_id, 5)
    top = List.first(top_members)
    most_warned = Members.get_most_warned(server_id)

    employee_of_month = if top, do: "<@#{top.user_id}>", else: nobody_label(locale)
    most_processed = if most_warned,
      do: "<@#{most_warned.user_id}> (#{most_warned.warns_count} #{warns_label(locale)})",
      else: nobody_label(locale)

    content = """
    #{Enum.random(michael_dashboard_lines(locale))}

    🏆 **#{employee_of_month_label(locale)}:** #{employee_of_month}
    ⚠️ **#{most_documented_label(locale)}:** #{most_processed}
    💵 **#{top_balance_label(locale)}:** #{if top, do: "#{top.schrute_bucks} SB", else: not_available_label(locale)}

    **#{sb_ranking_label(locale)}**
    #{sb_ranking_lines(locale, top_members)}

    _#{dgettext("economy", "dashboard_quote")}_
    """

    Router.defer_ephemeral(interaction)
    Router.send_as_character(interaction.channel_id, Michael, content)
    Router.delete_response(interaction)
  end

  defp calculate_threat(warns) do
    cond do
      warns == 0 -> "Harmless 😇"
      warns <= 2 -> "Mild 🟡"
      warns <= 5 -> "Elevated 🟠"
      warns <= 9 -> "Severe 🔴"
      true -> "EXTREME ☠️"
    end
  end

  defp michael_dashboard_lines("pt_BR") do
    [
      "E agora, o momento que todos aguardavam: o relatório trimestral. Preparado por mim. Michael Scott.",
      "Números. Eu amo números. Principalmente quando mostram como nossa filial é incrível.",
      "Bem-vindos ao relatório de desempenho da filial Scranton da Dunder Mifflin. Deixa que eu explico tudo."
    ]
  end

  defp michael_dashboard_lines(_locale) do
    [
      "And now, the moment you have all been waiting for — the quarterly report. Prepared by me. Michael Scott.",
      "Numbers. I love numbers. Especially when they show how amazing our branch is.",
      "Welcome to the Dunder Mifflin Scranton Branch performance review. Let me walk you through this."
    ]
  end

  defp employee_of_month_label("pt_BR"), do: "Funcionário do Mês"
  defp employee_of_month_label(_), do: "Employee of the Month"

  defp most_documented_label("pt_BR"), do: "Mais Documentado"
  defp most_documented_label(_), do: "Most Documented"

  defp top_balance_label("pt_BR"), do: "Maior Saldo"
  defp top_balance_label(_), do: "Top Balance"

  defp warns_label("pt_BR"), do: "avisos"
  defp warns_label(_), do: "warns"

  defp nobody_label("pt_BR"), do: "Ninguém"
  defp nobody_label(_), do: "Nobody"

  defp not_available_label("pt_BR"), do: "N/D"
  defp not_available_label(_), do: "N/A"

  defp sb_ranking_label("pt_BR"), do: "Ranking de Schrute Bucks (Top 5)"
  defp sb_ranking_label(_), do: "Schrute Bucks Ranking (Top 5)"

  defp sb_ranking_lines(locale, []), do: nobody_label(locale)

  defp sb_ranking_lines(_locale, members) do
    members
    |> Enum.with_index(1)
    |> Enum.map(fn {member, pos} ->
      "#{pos}. <@#{member.user_id}> — #{member.schrute_bucks} SB"
    end)
    |> Enum.join("\n")
  end
end
