defmodule DunderMifflinBot.Workers.EventWorker do
  use Oban.Worker, queue: :events, max_attempts: 3

  alias DunderMifflinBot.{Servers, Members, Events}
  alias DunderMifflinBot.AI.OpenAI

  @impl true
  def perform(%Oban.Job{args: %{"type" => "scheduled_check"}}) do
    servers = Servers.list_with_event_channel()

    for server <- servers do
      frequency = Map.get(server.config, "frequency", 2)
      fire_probability = frequency / 48.0

      if :rand.uniform() < fire_probability do
        fire_random_event(server)
      end
    end

    :ok
  end

  def perform(%Oban.Job{args: %{"type" => "birthday_check"}}) do
    servers = Servers.list_with_event_channel()

    for server <- servers do
      if Map.get(server.config, "birthday", true) do
        members = Members.list_with_birthday_today(server.server_id)

        for member <- members do
          fire_birthday(server, member.user_id)
        end
      end
    end

    :ok
  end

  def perform(%Oban.Job{args: %{"type" => "shift_end_check"}}) do
    now = Time.utc_now()
    servers = Servers.list_with_event_channel()

    for server <- servers do
      shift_end = Map.get(server.config, "shift_end", "17:00")
      {:ok, shift_time} = Time.from_iso8601("#{shift_end}:00")

      if abs(Time.diff(now, shift_time, :second)) < 60 do
        fire_shift_end(server)
      end
    end

    :ok
  end

  defp fire_random_event(server) do
    locale = server.language
    events = ["meeting", "pretzel_day", "twss_bait"]
    event_type = Enum.random(events)

    system = DunderMifflinBot.Characters.Michael.system_prompt() <>
      "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    content =
      case event_type do
        "meeting" ->
          {:ok, text} = OpenAI.complete(system, DunderMifflinBot.Characters.Michael.format_context(%{event: :meeting, members: []}))
          text

        "pretzel_day" ->
          {:ok, text} = OpenAI.complete(
            DunderMifflinBot.Characters.Stanley.system_prompt() <> "\n\nIMPORTANT: Respond in #{locale_label(locale)}.",
            DunderMifflinBot.Characters.Stanley.format_context(%{event: :pretzel_day})
          )
          "🥨 **PRETZEL DAY**\n\n**Stanley:** #{text}"

        _ ->
          if locale == "pt_BR",
            do: "Michael Scott está olhando pela janela. O escritório está em silêncio. Algo está prestes a acontecer.",
            else: "Michael Scott is staring out the window. The office is quiet. Something is about to happen."
      end

    Nostrum.Api.Message.create(server.event_channel_id, content)
    Servers.decrement_event_credits(server.server_id)

    Events.log_event(%{
      server_id: server.server_id,
      type: if(event_type == "pretzel_day", do: "pretzel_day", else: "meeting"),
      content: content
    })
  end

  defp fire_shift_end(server) do
    locale = server.language

    system = DunderMifflinBot.Characters.Stanley.system_prompt() <>
      "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    {:ok, text} = OpenAI.complete(system, "It's end of shift time. Announce that you're leaving. Maximum joy.")
    Nostrum.Api.Message.create(server.event_channel_id, "**Stanley:** #{text}")

    Events.log_event(%{
      server_id: server.server_id,
      type: "end_shift",
      content: text
    })
  end

  defp fire_birthday(server, user_id) do
    locale = server.language

    system = DunderMifflinBot.Characters.Angela.system_prompt() <>
      "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    {:ok, text} = OpenAI.complete(
      system,
      "Announce <@#{user_id}>'s birthday with minimal enthusiasm. You're on the party planning committee but you hate parties."
    )

    Nostrum.Api.Message.create(server.event_channel_id, "🎂 **BIRTHDAY ANNOUNCEMENT**\n**Angela:** #{text}")

    Events.log_event(%{
      server_id: server.server_id,
      type: "birthday",
      content: text,
      mentioned_users: [user_id]
    })
  end

  defp locale_label("pt_BR"), do: "Brazilian Portuguese (pt-BR) only. Do not mix with English except unavoidable proper names"
  defp locale_label(_), do: "English only. Do not mix with Portuguese except unavoidable proper names"
end
