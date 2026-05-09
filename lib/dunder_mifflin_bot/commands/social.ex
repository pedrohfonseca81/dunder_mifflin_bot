defmodule DunderMifflinBot.Commands.Social do
  use Gettext, backend: DunderMifflinBot.Gettext

  alias DunderMifflinBot.{Members, Moderation, Meetings}
  alias DunderMifflinBot.Commands.Router
  alias DunderMifflinBot.AI.OpenAI
  alias DunderMifflinBot.Characters.{Michael, Dwight, Kevin}

  def handle_meeting(interaction, target_id, topic, locale) do
    server_id = interaction.guild_id
    caller_id = interaction.member.user_id
    channel_id = interaction.channel_id

    Router.defer_ephemeral(interaction)

    with {:ok, meeting} <-
           Meetings.create_meeting(%{
             server_id: server_id,
             channel_id: channel_id,
             caller_user_id: caller_id,
             target_user_id: target_id,
             topic: topic
           }),
         {:ok, _job} <-
           %{"meeting_id" => meeting.id, "step" => 1, "locale" => locale}
           |> DunderMifflinBot.Workers.MeetingWorker.new()
           |> Oban.insert() do
      michael_lines =
        if locale == "pt_BR" do
          [
            "<@#{target_id}> — minha sala. Agora. É sobre #{topic}. Isso não é opcional.",
            "Atenção, pessoal. <@#{target_id}> foi convocado para a sala de reunião. Assunto: #{topic}. Coisa grande.",
            "<@#{target_id}>, sala de reunião. Cinco minutos. Assunto: #{topic}. Não se atrase."
          ]
        else
          [
            "<@#{target_id}> — my office. Now. It's about #{topic}. This is not optional.",
            "Attention everyone. <@#{target_id}> has been summoned to the conference room. Topic: #{topic}. Big stuff.",
            "<@#{target_id}>, conference room. Five minutes. Topic: #{topic}. Do not be late."
          ]
        end

      Router.send_as_character(channel_id, Michael, Enum.random(michael_lines))
      Router.delete_response(interaction)
    else
      {:error, reason} ->
        Router.edit_response(interaction, "Erro ao iniciar reunião: #{inspect(reason)}")
    end
  end

  def handle_trial(interaction, target_id, reason, locale) do
    server_id = interaction.guild_id
    author_id = interaction.member.user_id

    Router.defer_ephemeral(interaction)

    prompt_michael = DunderMifflinBot.Characters.Michael.system_prompt() <>
      "\n\nIMPORTANT: Respond in #{locale_label(locale)}."
    prompt_dwight = DunderMifflinBot.Characters.Dwight.system_prompt() <>
      "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    target_mention = "<@#{target_id}>"

    {:ok, michael_opening} = OpenAI.complete(
      prompt_michael,
      "Open a Dunder Mifflin Court trial. You are judge Michael Scott. The defendant is #{target_mention} accused of: #{reason}. Be dramatic."
    )

    {:ok, dwight_prosecution} = OpenAI.complete(
      prompt_dwight,
      "Present the prosecution case against #{target_mention} for: #{reason}. Be formal and militaristic."
    )

    Moderation.log_incident(%{
      server_id: server_id,
      type: "trial",
      target_user_id: target_id,
      author_user_id: author_id,
      reason: reason,
      ai_response: "#{michael_opening}\n\n#{dwight_prosecution}"
    })

    Router.send_as_character(interaction.channel_id, Michael,
      "⚖️ **DUNDER MIFFLIN COURT IS NOW IN SESSION**\n\n#{michael_opening}")
    Router.send_as_character(interaction.channel_id, Dwight,
      "**PROSECUTION:** #{dwight_prosecution}\n\nReact with ✅ innocent or ❌ guilty.")
    Router.delete_response(interaction)
  end

  def handle_alliance(interaction, target_mention, _locale) do
    n = Enum.random(1..3)
    msg = Gettext.dgettext(DunderMifflinBot.Gettext, "default", "alliance_#{n}", target: target_mention)

    Router.defer_ephemeral(interaction)
    Router.send_as_character(interaction.channel_id, Dwight, msg)
    Router.delete_response(interaction)
  end

  def handle_vote(interaction, option1, option2, _locale) do
    n = Enum.random(1..4)
    commentary = Gettext.dgettext(DunderMifflinBot.Gettext, "default", "vote_commentary_#{n}")

    kevin_lines = [
      "Okay so... vote. **#{option1}** or **#{option2}**. React. 🅰️ or 🅱️. Kevin likes both actually.",
      "Poll time! 🅰️ **#{option1}** vs 🅱️ **#{option2}**. This is important. Maybe. Kevin is not sure.",
      "Vote! 🅰️ for **#{option1}**. 🅱️ for **#{option2}**. Kevin has voted. Won't say which."
    ]

    msg = """
    🗳️ **OFFICE POLL**

    React to vote:
    🅰️ **#{option1}**
    🅱️ **#{option2}**

    _#{commentary}_
    """

    Router.defer_ephemeral(interaction)
    Router.send_as_character(interaction.channel_id, Kevin, Enum.random(kevin_lines))
    Nostrum.Api.Message.create(interaction.channel_id, msg)
    Router.delete_response(interaction)
  end

  def handle_dundie(interaction, target_id, category, locale) do
    Router.defer_ephemeral(interaction)

    system = DunderMifflinBot.Characters.Michael.system_prompt() <>
      "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    {:ok, speech} = OpenAI.complete(
      system,
      "Present the Dundie Award for '#{category}' to <@#{target_id}>. Be dramatic and self-important. This is your Oscar moment."
    )

    Members.add_dundie(target_id, interaction.guild_id, category)

    Router.send_as_character(
      interaction.channel_id,
      Michael,
      "🏆 **AND THE DUNDIE GOES TO...**\n\n#{speech}"
    )
    Router.delete_response(interaction)
  end

  defp locale_label("pt_BR"), do: "Brazilian Portuguese (pt-BR) only. Do not mix with English except unavoidable proper names"
  defp locale_label(_), do: "English only. Do not mix with Portuguese except unavoidable proper names"
end
