defmodule DunderMifflinBot.Commands.Moderation do
  use Gettext, backend: DunderMifflinBot.Gettext

  alias DunderMifflinBot.{Members, Moderation, Servers}
  alias DunderMifflinBot.Commands.Router
  alias DunderMifflinBot.Characters.{Dwight, Toby, Michael}

  def handle_warn(interaction, target_id, reason, _locale) do
    server_id = interaction.guild_id
    author_id = interaction.member.user_id

    member = Members.get_or_create(target_id, server_id)
    new_count = member.warns_count + 1

    Members.increment_warns(target_id, server_id)

    Moderation.log_incident(%{
      server_id: server_id,
      type: "warn",
      target_user_id: target_id,
      author_user_id: author_id,
      reason: reason
    })

    threshold = Servers.get_config(server_id, :warns_threshold, 3)
    auto_mute = new_count >= threshold

    dwight_lines = [
      "Warning issued to <@#{target_id}>. Reason: #{reason}. This is warn number #{new_count}. I document everything.",
      "FORMAL WARNING — <@#{target_id}>. Reason: #{reason}. This has been logged in the incident report binder. Warning ##{new_count}.",
      "Incident recorded. <@#{target_id}> has received warning #{new_count}. Reason: #{reason}. I take these very seriously."
    ]

    suffix = if auto_mute, do: " Auto-mute threshold reached (#{new_count}/#{threshold}). Applied.", else: ""

    Router.defer_ephemeral(interaction)
    Router.send_as_character(interaction.channel_id, Dwight, Enum.random(dwight_lines) <> suffix)
    Router.delete_response(interaction)

    if auto_mute do
      Nostrum.Api.Guild.modify_member(server_id, target_id, communication_disabled_until: mute_until(3600))
    end
  end

  def handle_mute(interaction, target_id, time_str, reason, _locale) do
    server_id = interaction.guild_id
    author_id = interaction.member.user_id
    seconds = parse_duration(time_str)

    Nostrum.Api.Guild.modify_member(server_id, target_id,
      communication_disabled_until: mute_until(seconds))

    Moderation.log_incident(%{
      server_id: server_id,
      type: "mute",
      target_user_id: target_id,
      author_user_id: author_id,
      reason: reason
    })

    toby_lines = [
      "I've, um... I've muted <@#{target_id}> for #{time_str}. HR policy requires documentation. Reason: #{reason}. This is not personal.",
      "Mute applied. <@#{target_id}> will be silent for #{time_str}. I just... I feel bad about it. But policy is policy. Reason: #{reason}.",
      "Per HR guidelines, <@#{target_id}> has been muted for #{time_str}. Reason: #{reason}. I hope this resolves the situation."
    ]

    Router.defer_ephemeral(interaction)
    Router.send_as_character(interaction.channel_id, Toby, Enum.random(toby_lines))
    Router.delete_response(interaction)
  end

  def handle_timeout(interaction, target_id, time_str, reason, _locale) do
    server_id = interaction.guild_id
    author_id = interaction.member.user_id
    seconds = parse_duration(time_str)

    Nostrum.Api.Guild.modify_member(server_id, target_id,
      communication_disabled_until: mute_until(seconds))

    Moderation.log_incident(%{
      server_id: server_id,
      type: "timeout",
      target_user_id: target_id,
      author_user_id: author_id,
      reason: reason
    })

    toby_lines = [
      "Timeout issued. <@#{target_id}> needs a moment to reflect. Duration: #{time_str}. Reason: #{reason}.",
      "I've applied a #{time_str} timeout to <@#{target_id}>. This is a cooling-off period. Reason: #{reason}. Very standard.",
      "Temporary timeout. <@#{target_id}>, #{time_str}. Reason: #{reason}. I didn't want to do this but here we are."
    ]

    Router.defer_ephemeral(interaction)
    Router.send_as_character(interaction.channel_id, Toby, Enum.random(toby_lines))
    Router.delete_response(interaction)
  end

  def handle_kick(interaction, target_id, reason, _locale) do
    server_id = interaction.guild_id
    author_id = interaction.member.user_id

    Nostrum.Api.Guild.kick_member(server_id, target_id)

    Moderation.log_incident(%{
      server_id: server_id,
      type: "kick",
      target_user_id: target_id,
      author_user_id: author_id,
      reason: reason
    })

    michael_lines = [
      "And <@#{target_id}> has LEFT THE BUILDING. Reason: #{reason}. This was not easy for me. Actually it was a little bit.",
      "FIRED! Well, kicked. Same energy. Goodbye <@#{target_id}>. Reason: #{reason}. You will not be forgotten. Probably.",
      "<@#{target_id}> is out. Gone. The branch moves on. Reason: #{reason}. I am the one who made this call. Me."
    ]

    Router.defer_ephemeral(interaction)
    Router.send_as_character(interaction.channel_id, Michael, Enum.random(michael_lines))
    Router.delete_response(interaction)
  end

  def handle_ban(interaction, target_id, reason, _locale) do
    server_id = interaction.guild_id
    author_id = interaction.member.user_id

    Nostrum.Api.Guild.ban_member(server_id, target_id, delete_message_seconds: 0)

    Moderation.log_incident(%{
      server_id: server_id,
      type: "ban",
      target_user_id: target_id,
      author_user_id: author_id,
      reason: reason
    })

    michael_lines = [
      "⛔ <@#{target_id}> is BANNED. PERMANENTLY. Reason: #{reason}. I do not make this decision lightly. But I did make it.",
      "PERMANENT BAN. <@#{target_id}>, you are done here. Reason: #{reason}. Michael Scott has spoken.",
      "<@#{target_id}> — banned. Forever. Reason: #{reason}. I am a fair manager but I am also a decisive one."
    ]

    Router.defer_ephemeral(interaction)
    Router.send_as_character(interaction.channel_id, Michael, Enum.random(michael_lines))
    Router.delete_response(interaction)
  end

  def handle_logs(interaction, _locale) do
    server_id = interaction.guild_id
    incidents = Moderation.list_for_server(server_id, 10)

    Router.defer_ephemeral(interaction)

    if Enum.empty?(incidents) do
      Router.send_as_character(interaction.channel_id, Dwight, "No incidents on file. Either this branch is exemplary, or people are hiding things. I suspect the latter.")
    else
      lines =
        incidents
        |> Enum.map(fn i ->
          date = Calendar.strftime(i.inserted_at, "%Y-%m-%d")
          "• `#{date}` **#{i.type}** → <@#{i.target_user_id}> — #{i.reason || "no reason"}"
        end)
        |> Enum.join("\n")

      Router.send_as_character(interaction.channel_id, Dwight, "📁 **INCIDENT FILES — Classified**\nI maintain these records personally. Review them carefully.\n\n#{lines}")
    end

    Router.delete_response(interaction)
  end

  def handle_rules_set(interaction, content, _locale) do
    server_id = interaction.guild_id
    Servers.set_config(server_id, :rules, content)

    Router.defer_ephemeral(interaction)
    Router.send_as_character(interaction.channel_id, Dwight, "Employee Manual updated. I have reviewed the new content. Compliance is mandatory. Ignorance is not an excuse.")
    Router.delete_response(interaction)
  end

  def handle_rules_view(interaction, _locale) do
    server_id = interaction.guild_id
    rules = Servers.get_config(server_id, :rules, nil)

    Router.defer_ephemeral(interaction)

    if rules do
      Router.send_as_character(interaction.channel_id, Dwight, "📋 **EMPLOYEE MANUAL — Dunder Mifflin**\nRead. Memorize. Comply.\n\n#{rules}")
    else
      Router.send_as_character(interaction.channel_id, Dwight, "No Employee Manual on file. This is unacceptable. An office without rules is an office without order. Set one immediately.")
    end

    Router.delete_response(interaction)
  end

  defp parse_duration(str) when is_binary(str) do
    cond do
      String.ends_with?(str, "m") -> String.to_integer(String.trim_trailing(str, "m")) * 60
      String.ends_with?(str, "h") -> String.to_integer(String.trim_trailing(str, "h")) * 3600
      String.ends_with?(str, "d") -> String.to_integer(String.trim_trailing(str, "d")) * 86400
      true -> 3600
    end
  end

  defp parse_duration(_), do: 3600

  defp mute_until(seconds) do
    DateTime.utc_now()
    |> DateTime.add(seconds, :second)
    |> DateTime.to_iso8601()
  end
end
