defmodule DunderMifflinBot.Commands.Utility do
  use Gettext, backend: DunderMifflinBot.Gettext

  alias DunderMifflinBot.AI.OpenAI
  alias DunderMifflinBot.Characters.{Michael, Toby}
  alias DunderMifflinBot.{Members, Servers}
  alias DunderMifflinBot.Commands.Router

  def handle_toby(interaction, target, reason, locale) do
    toby_system = Toby.system_prompt() <> "\n\nIMPORTANT: Respond in #{locale_label(locale)}."
    michael_system = Toby.michael_interruption_prompt() <> "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    {:ok, toby_text} = OpenAI.complete(toby_system, Toby.format_context(%{target: target, reason: reason}))
    {:ok, michael_interrupt} = OpenAI.complete(michael_system, "Toby just said: '#{toby_text}'. Interrupt him.")

    msg = """
    **Toby:** #{toby_text}...

    **Michael:** #{michael_interrupt}
    """

    Router.reply(interaction, msg)
  end

  def handle_summary(interaction, locale) do
    channel_id = interaction.channel_id

    messages =
      case Nostrum.Api.Channel.messages(channel_id, 50) do
        {:ok, msgs} ->
          msgs
          |> Enum.reverse()
          |> Enum.reject(&(&1.content == ""))
          |> Enum.map(fn m -> "#{m.author.username}: #{m.content}" end)
          |> Enum.join("\n")

        _ ->
          "No recent messages found."
      end

    system = Michael.system_prompt() <> "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    {:ok, summary} =
      OpenAI.complete(
        system,
        "Narrate a summary of these recent chat messages as if they were an episode of The Office. Give it a title and treat it like a TV recap:\n\n#{messages}"
      )

    Router.reply(interaction, "#{dgettext("economy", "summary_header")}\n\n#{summary}")
  end

  def handle_translate(interaction, text, language, locale) do
    translation_system = """
    You are a professional translator. Translate the given text accurately.
    Respond with ONLY the translation, nothing else.
    """

    oscar_system = DunderMifflinBot.Characters.Oscar.system_prompt() <>
      "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    {:ok, translation} = OpenAI.complete(translation_system, "Translate to #{language}: #{text}")

    {:ok, oscar_comment} =
      OpenAI.complete(
        oscar_system,
        DunderMifflinBot.Characters.Oscar.format_context(%{text: translation, language: language})
      )

    msg = """
    #{dgettext("economy", "translate_header", language: language)}
    #{translation}

    **Oscar:** #{oscar_comment}
    """

    Router.reply(interaction, msg)
  end

  def handle_reminder(interaction, target_id, time_str, message, locale) do
    seconds = parse_duration(time_str)
    scheduled_at = DateTime.add(DateTime.utc_now(), seconds, :second)

    %{
      "user_id" => target_id,
      "server_id" => interaction.guild_id,
      "channel_id" => interaction.channel_id,
      "message" => message,
      "locale" => locale
    }
    |> DunderMifflinBot.Workers.ReminderWorker.new(scheduled_at: scheduled_at)
    |> Oban.insert!()

    Router.reply_ephemeral(interaction, dgettext("economy", "reminder_set",
      target: "<@#{target_id}>", time: time_str))
  end

  def handle_birthday(interaction, date_str, _locale) do
    user_id = interaction.member.user_id
    server_id = interaction.guild_id

    case parse_birthday(date_str) do
      {:ok, normalized} ->
        Members.set_birthday(user_id, server_id, normalized)
        Router.reply_ephemeral(interaction, dgettext("economy", "birthday_registered", date: normalized))

      :error ->
        Router.reply_ephemeral(interaction, dgettext("economy", "birthday_invalid"))
    end
  end

  defp parse_birthday(str) when is_binary(str) do
    str = String.trim(str)

    cond do
      Regex.match?(~r/^\d{2}\/\d{2}$/, str) ->
        [dd, mm] = String.split(str, "/")
        validate_birthday(mm, dd)

      Regex.match?(~r/^\d{2}-\d{2}$/, str) ->
        [mm, dd] = String.split(str, "-")
        validate_birthday(mm, dd)

      true ->
        :error
    end
  end

  defp parse_birthday(_), do: :error

  defp validate_birthday(mm, dd) do
    month = String.to_integer(mm)
    day = String.to_integer(dd)

    if month in 1..12 and day in 1..31 do
      {:ok, "#{String.pad_leading(mm, 2, "0")}-#{String.pad_leading(dd, 2, "0")}"}
    else
      :error
    end
  end

  def handle_config_panel(interaction) do
    Nostrum.Api.Interaction.create_response(interaction, %{type: 5, data: %{flags: 64}})

    try do
      data = config_panel_data(interaction.guild_id)
      result = Nostrum.Api.Interaction.edit_response(interaction, data)
      require Logger
      Logger.debug("config panel edit_response result: #{inspect(result)}")
    rescue
      e ->
        require Logger
        Logger.error("config panel error: #{inspect(e)}\n#{inspect(__STACKTRACE__)}")
        Nostrum.Api.Interaction.edit_response(interaction, %{content: "Error: #{inspect(e)}"})
    end
  end

  def config_panel_data(server_id) do
    server = Servers.get_or_create(server_id)
    cfg = server.config || %{}

    language        = server.language || "en"
    frequency       = Map.get(cfg, "frequency", 2)
    birthday        = Map.get(cfg, "birthday", true)
    shift_end       = Map.get(cfg, "shift_end", "17:00")
    twss            = Map.get(cfg, "twss", true)
    twss_max        = Map.get(cfg, "twss_max", 3)
    warns_threshold = Map.get(cfg, "warns_threshold", 3)
    event_channel   = if server.event_channel_id, do: "<##{server.event_channel_id}>", else: "—"

    lang_label = if language == "pt_BR", do: "🇧🇷 Português (BR)", else: "🇺🇸 English"

    embed = %{
      title: "⚙️ Server Configuration",
      color: 0x1F6FEB,
      fields: [
        %{name: "🌐 Language",           value: lang_label,                             inline: true},
        %{name: "📺 Event Channel",       value: event_channel,                          inline: true},
        %{name: "🔄 Event Frequency",     value: "#{frequency}x/period",                 inline: true},
        %{name: "🎂 Birthdays",           value: if(birthday, do: "✅ On", else: "❌ Off"), inline: true},
        %{name: "⏰ Shift End",           value: shift_end,                              inline: true},
        %{name: "💬 TWSS Detection",      value: if(twss, do: "✅ On", else: "❌ Off"),   inline: true},
        %{name: "📊 TWSS Max/Day",        value: to_string(twss_max),                    inline: true},
        %{name: "⚠️ Warn Threshold",      value: to_string(warns_threshold),             inline: true}
      ],
      footer: %{text: "Changes apply immediately • Dunder Mifflin HR"}
    }

    opt  = fn label, key, val -> %{label: label, value: "#{key}:#{val}"} end
    bool = fn key, label_on, label_off -> [opt.(label_on, key, "true"), opt.(label_off, key, "false")] end

    lang_cur  = if language == "pt_BR", do: "pt_BR", else: "en"
    twss_cur  = if twss, do: "✅", else: "❌"
    bday_cur  = if birthday, do: "✅", else: "❌"

    components = [
      %{type: 1, components: [%{
        type: 3, custom_id: "config_select_lang",
        placeholder: "🌐 Language — now: #{lang_cur}",
        options: [
          opt.("🇺🇸 English", "language", "en"),
          opt.("🇧🇷 Português (BR)", "language", "pt_BR")
        ]
      }]},
      %{type: 1, components: [%{
        type: 3, custom_id: "config_select_freq",
        placeholder: "🔄 Frequency: #{frequency}x  |  ⚠️ Warn threshold: #{warns_threshold}",
        options:
          Enum.map([1, 2, 3, 5], &opt.("🔄 Frequency: #{&1}x", "frequency", &1)) ++
          Enum.map([2, 3, 4, 5], &opt.("⚠️ Warn threshold: #{&1}", "warns_threshold", &1))
      }]},
      %{type: 1, components: [%{
        type: 3, custom_id: "config_select_misc",
        placeholder: "📊 TWSS max: #{twss_max}  |  ⏰ Shift end: #{shift_end}",
        options:
          Enum.map([1, 2, 3, 5, 10], &opt.("📊 TWSS max: #{&1}/day", "twss_max", &1)) ++
          Enum.map(["08:00", "09:00", "17:00", "18:00"], &opt.("⏰ Shift end: #{&1}", "shift_end", &1))
      }]},
      %{type: 1, components: [%{
        type: 3, custom_id: "config_select_toggle",
        placeholder: "💬 TWSS: #{twss_cur}  |  🎂 Birthdays: #{bday_cur}",
        options:
          bool.("twss", "💬 TWSS On", "💬 TWSS Off") ++
          bool.("birthday", "🎂 Birthdays On", "🎂 Birthdays Off")
      }]}
    ]

    %{embeds: [embed], components: components}
  end

  def handle_help(interaction, locale) do
    Router.reply_ephemeral(interaction, dgettext("default", "help", locale: locale))
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

  defp locale_label("pt_BR"), do: "Brazilian Portuguese (pt-BR) only. Do not mix with English except unavoidable proper names"
  defp locale_label(_), do: "English only. Do not mix with Portuguese except unavoidable proper names"
end
