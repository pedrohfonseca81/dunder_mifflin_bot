defmodule DunderMifflinBot.Consumer do
  use Nostrum.Consumer

  alias DunderMifflinBot.Commands.Router
  alias DunderMifflinBot.Detector.TWSS
  alias DunderMifflinBot.{Servers, Events, Meetings, CharacterSession}
  alias DunderMifflinBot.Characters.Character
  alias DunderMifflinBot.AI.OpenAI
  alias DunderMifflinBot.Economy.Wallet

  def handle_event({:READY, _data, _ws_state}) do
    DunderMifflinBot.Commands.Registry.register_global()
    :ok
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    case interaction.type do
      2 -> Router.handle(interaction)
      3 -> handle_component(interaction)
      5 -> handle_modal(interaction)
      _ -> :ignore
    end
  end

  def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
    if !message.author.bot do
      handle_message(message)
    end
  end

  def handle_event(_event), do: :noop

  defp handle_message(message) do
    case DunderMifflinBot.Commands.Prefix.parse(message) do
      nil ->
        case CharacterSession.get_session(message.channel_id, message.author.id) do
          nil -> handle_twss(message)
          session -> handle_character_reply(message, session)
        end

      mock_interaction ->
        Router.handle(mock_interaction)
    end
  end

  defp handle_twss(message) do
    server = Servers.get_or_create(message.guild_id)
    locale = server.language || "en"

    Gettext.put_locale(DunderMifflinBot.Gettext, locale)

    twss_on = Map.get(server.config, "twss", true)
    twss_max = Map.get(server.config, "twss_max", 3)
    event_channel = server.event_channel_id
    in_event_channel = event_channel && message.channel_id == event_channel

    if twss_on && in_event_channel && TWSS.twss?(message.content, locale) do
      twss_today = Events.count_twss_today(message.guild_id)

      if twss_today < twss_max do
        Nostrum.Api.Message.create(message.channel_id, TWSS.michael_response(locale))

        Events.log_event(%{
          server_id: message.guild_id,
          type: "twss",
          content: message.content
        })
      end
    end
  end

  defp handle_character_reply(message, %{character: char, history: history, locale: locale}) do
    channel_id = message.channel_id
    user_id = message.author.id
    server_id = message.guild_id

    case Wallet.debit(user_id, server_id, 2, "chat_session") do
      {:ok, _} ->
        system = Character.build_prompt(char, locale)
        messages = history ++ [%{role: "user", content: message.content}]

        case OpenAI.complete_conversation(system, messages) do
          {:ok, reply} ->
            Router.send_as_character(channel_id, char, reply)
            CharacterSession.add_exchange(channel_id, user_id, message.content, reply)
          _ ->
            :ok
        end

      {:error, :insufficient_funds} ->
        CharacterSession.end_session(channel_id, user_id)
        Nostrum.Api.Message.create(channel_id, "<@#{user_id}> Sem Schrute Bucks. Conversa encerrada.")

      _ ->
        :ok
    end
  end

  defp handle_component(%{data: %{custom_id: "meeting_respond_" <> meeting_id}} = interaction) do
    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 9,
      data: %{
        title: "Your Response",
        custom_id: "meeting_modal_#{meeting_id}",
        components: [
          %{
            type: 1,
            components: [
              %{
                type: 4,
                custom_id: "response_text",
                label: "What do you say?",
                style: 2,
                required: true
              }
            ]
          }
        ]
      }
    })
  end

  defp handle_component(%{data: %{custom_id: "meeting_silent_" <> meeting_id}} = interaction) do
    meeting = Meetings.get_meeting(meeting_id)

    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 4,
      data: %{content: "You stayed silent. Michael is disappointed.", flags: 64}
    })

    if meeting do
      locale = Servers.get_language(meeting.server_id)

      %{"meeting_id" => meeting_id, "step" => 4, "locale" => locale}
      |> DunderMifflinBot.Workers.MeetingWorker.new()
      |> Oban.insert!()
    end
  end

  defp handle_component(%{data: %{custom_id: "config_select" <> _, values: [value]}} = interaction) do
    server_id = interaction.guild_id
    [key, val] = String.split(value, ":", parts: 2)

    case key do
      "language" ->
        Servers.set_language(server_id, val)

      "frequency" ->
        Servers.set_config(server_id, :frequency, String.to_integer(val))

      "warns_threshold" ->
        Servers.set_config(server_id, :warns_threshold, String.to_integer(val))

      "twss_max" ->
        Servers.set_config(server_id, :twss_max, String.to_integer(val))

      "shift_end" ->
        Servers.set_config(server_id, :shift_end, val)

      "twss" ->
        Servers.set_config(server_id, :twss, val == "true")

      "birthday" ->
        Servers.set_config(server_id, :birthday, val == "true")

      _ ->
        Servers.set_config(server_id, String.to_atom(key), val)
    end

    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 7,
      data: DunderMifflinBot.Commands.Utility.config_panel_data(server_id)
    })
  end

  defp handle_component(%{data: %{custom_id: "store_" <> pack_id}} = interaction) do
    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 9,
      data: %{
        title: "Dados para o PIX",
        custom_id: "store_modal_#{pack_id}",
        components: [
          %{
            type: 1,
            components: [
              %{
                type: 4,
                custom_id: "phone",
                label: "Celular (com DDD, só números)",
                style: 1,
                placeholder: "11999999999",
                min_length: 10,
                max_length: 11,
                required: true
              }
            ]
          },
          %{
            type: 1,
            components: [
              %{
                type: 4,
                custom_id: "cpf",
                label: "CPF (só números)",
                style: 1,
                placeholder: "12345678901",
                min_length: 11,
                max_length: 14,
                required: true
              }
            ]
          }
        ]
      }
    })
  end

  defp handle_component(_interaction), do: :ignore

  defp handle_modal(%{data: %{custom_id: "store_modal_" <> pack_id}} = interaction) do
    user_id = interaction.member.user_id

    fields = interaction.data.components |> Enum.flat_map(& &1.components)

    phone =
      fields
      |> Enum.find(&(&1.custom_id == "phone"))
      |> then(& &1.value)
      |> String.replace(~r/\D/, "")

    cpf_raw =
      fields
      |> Enum.find(&(&1.custom_id == "cpf"))
      |> then(& &1.value)
      |> String.replace(~r/\D/, "")

    cpf = format_cpf(cpf_raw)

    customer = %{
      name: "discord_#{user_id}",
      email: "#{user_id}@discord.user",
      taxId: cpf,
      cellphone: phone
    }

    Nostrum.Api.Interaction.create_response(interaction, %{type: 5, data: %{flags: 64}})

    case DunderMifflinBot.Economy.Store.create_sb_purchase(user_id, interaction.guild_id, pack_id, customer) do
      {:ok, charge} ->
        Nostrum.Api.Interaction.edit_response(interaction, %{
          content: pix_payment_message(charge)
        })

      {:error, reason} ->
        Nostrum.Api.Interaction.edit_response(interaction, %{content: "Erro ao gerar pagamento: #{inspect(reason)}"})
    end
  end

  defp handle_modal(%{data: %{custom_id: "meeting_modal_" <> meeting_id}} = interaction) do
    response_text =
      interaction.data.components
      |> Enum.flat_map(& &1.components)
      |> Enum.find(&(&1.custom_id == "response_text"))
      |> then(& &1.value)

    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 4,
      data: %{content: "✅ Resposta enviada!", flags: 64}
    })

    meeting = Meetings.get_meeting(meeting_id)

    if meeting do
      locale = Servers.get_language(meeting.server_id)
      Meetings.update_status(meeting.id, "completed")

      spawn(fn ->
        alias DunderMifflinBot.AI.OpenAI
        lang = if locale == "pt_BR", do: "Brazilian Portuguese (pt-BR)", else: "English"
        system = DunderMifflinBot.Characters.Michael.system_prompt() <>
          "\n\nIMPORTANT: Respond in #{lang}."
        {:ok, text} = OpenAI.complete(
          system,
          "The target of the meeting said: '#{response_text}'. React dramatically as Michael. Close the meeting."
        )
        Router.send_as_character(meeting.channel_id, DunderMifflinBot.Characters.Michael, text)
      end)
    end
  end

  defp handle_modal(_interaction), do: :ignore

  defp format_cpf(digits) when byte_size(digits) == 11 do
    <<a::binary-3, b::binary-3, c::binary-3, d::binary-2>> = digits
    "#{a}.#{b}.#{c}-#{d}"
  end

  defp format_cpf(digits), do: digits

  defp pix_payment_message(charge) do
    br_code =
      charge["brCode"] ||
        charge["qrCode"] ||
        charge["pixCode"] ||
        ""

    base = "💰 **PIX Copia e Cola:**\n```\n#{br_code}\n```"

    case pix_qr_url(charge, br_code) do
      nil ->
        base <> "\nExpira em 30 minutos."

      qr_url ->
        base <> "\n🔳 **QR Code:** #{qr_url}\nExpira em 30 minutos."
    end
  end

  defp pix_qr_url(charge, br_code) do
    direct_url =
      [
        "qrCodeImageUrl",
        "qrCodeImage",
        "qrImage",
        "imageUrl",
        "paymentLink",
        "url"
      ]
      |> Enum.find_value(fn key ->
        value = charge[key]

        if is_binary(value) and String.starts_with?(value, "http") do
          value
        end
      end)

    cond do
      is_binary(direct_url) and direct_url != "" ->
        direct_url

      is_binary(br_code) and br_code != "" ->
        "https://api.qrserver.com/v1/create-qr-code/?size=360x360&data=#{URI.encode_www_form(br_code)}"

      true ->
        nil
    end
  end
end
