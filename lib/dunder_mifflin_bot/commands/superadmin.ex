defmodule DunderMifflinBot.Commands.Superadmin do
  alias DunderMifflinBot.Commands.{Registry, Router}
  alias DunderMifflinBot.Economy.Wallet

  def handle_ping(interaction) do
    Router.reply_ephemeral(interaction, "✅ Superadmin access granted.")
  end

  def handle_owners(interaction) do
    owners = Application.get_env(:dunder_mifflin_bot, :owners_ids, [])

    content =
      case owners do
        [] -> "OWNERS_ID is empty."
        ids -> "Configured owners:\n" <> Enum.map_join(ids, "\n", &"- <@#{&1}> (#{&1})")
      end

    Router.reply_ephemeral(interaction, content)
  end

  def handle_sync_commands(interaction) do
    Router.defer_ephemeral(interaction)

    case Registry.register_global() do
      {:ok, _commands} ->
        Router.edit_response(interaction, "✅ Global commands synced.")

      {:error, reason} ->
        Router.edit_response(interaction, "❌ Failed to sync commands: #{inspect(reason)}")

      other ->
        Router.edit_response(interaction, "⚠️ Unexpected response while syncing: #{inspect(other)}")
    end
  end

  def handle_grant_sb(interaction, target_id, amount) when is_integer(amount) and amount > 0 do
    server_id = interaction.guild_id

    case Wallet.credit(target_id, server_id, amount, "superadmin_grant") do
      {:ok, _} ->
        new_balance = Wallet.balance(target_id, server_id)

        Router.reply_ephemeral(
          interaction,
          "✅ Granted **#{amount} SB** to <@#{target_id}>. New balance: **#{new_balance} SB**."
        )

      {:error, reason} ->
        Router.reply_ephemeral(interaction, "❌ Failed to grant SB: #{inspect(reason)}")
    end
  end

  def handle_grant_sb(interaction, _target_id, _amount) do
    Router.reply_ephemeral(interaction, "❌ Invalid amount. Use a value >= 1.")
  end
end
