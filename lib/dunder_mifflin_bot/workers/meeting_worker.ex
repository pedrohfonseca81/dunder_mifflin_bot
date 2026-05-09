defmodule DunderMifflinBot.Workers.MeetingWorker do
  use Oban.Worker, queue: :meetings, max_attempts: 3
  use Gettext, backend: DunderMifflinBot.Gettext

  alias DunderMifflinBot.Meetings
  alias DunderMifflinBot.Characters.Character
  alias DunderMifflinBot.AI.OpenAI
  alias DunderMifflinBot.Commands.Router

  @step_delay 4_000

  @impl true
  def perform(%Oban.Job{args: %{"meeting_id" => meeting_id, "step" => step, "locale" => locale}}) do
    Gettext.put_locale(DunderMifflinBot.Gettext, locale)

    meeting = Meetings.get_meeting(meeting_id)

    case meeting do
      nil -> :ok
      %{status: "timeout"} -> :ok
      %{status: "completed"} -> :ok
      meeting -> handle_step(meeting, step, locale)
    end
  end

  defp handle_step(meeting, 1, locale) do
    system = DunderMifflinBot.Characters.Michael.system_prompt() <>
      "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    {:ok, text} = OpenAI.complete(
      system,
      DunderMifflinBot.Characters.Michael.format_context(%{
        topic: meeting.topic,
        target: "<@#{meeting.target_user_id}>"
      })
    )

    post_to_channel(meeting.channel_id, DunderMifflinBot.Characters.Michael, text)
    Meetings.append_message(meeting.id, %{"character" => "michael", "text" => text})
    schedule_next(meeting.id, 2, locale)
  end

  defp handle_step(meeting, 2, locale) do
    [char1 | _] = Character.random_characters(2)

    system = char1.system_prompt() <> "\n\nIMPORTANT: Respond in #{locale_label(locale)}."
    {:ok, text} = OpenAI.complete(system, "React to this meeting about '#{meeting.topic}' involving <@#{meeting.target_user_id}>.")

    char_name = char1 |> Module.split() |> List.last()
    post_to_channel(meeting.channel_id, char1, text)
    Meetings.append_message(meeting.id, %{"character" => char_name, "text" => text})

    schedule_next(meeting.id, 3, locale)
  end

  defp handle_step(meeting, 3, locale) do
    char = Character.random_characters(1) |> List.first()
    system = char.system_prompt() <> "\n\nIMPORTANT: Respond in #{locale_label(locale)}."
    {:ok, text} = OpenAI.complete(system, "Intervene in a meeting about '#{meeting.topic}'.")

    char_name = char |> Module.split() |> List.last()
    post_to_channel(meeting.channel_id, char, text)
    Meetings.append_message(meeting.id, %{"character" => char_name, "text" => text})

    prompt = dgettext("default", "meeting_respond_prompt", target: "<@#{meeting.target_user_id}>")

    Nostrum.Api.Message.create(meeting.channel_id, %{
      content: prompt,
      components: [
        %{
          type: 1,
          components: [
            %{type: 2, style: 1, label: "Respond!", custom_id: "meeting_respond_#{meeting.id}"},
            %{type: 2, style: 4, label: "Stay silent", custom_id: "meeting_silent_#{meeting.id}"}
          ]
        }
      ]
    })

    schedule_next(meeting.id, 4, locale, delay: 20_000)
  end

  defp handle_step(meeting, 4, locale) do
    system = DunderMifflinBot.Characters.Michael.system_prompt() <>
      "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    {:ok, text} = OpenAI.complete(
      system,
      "Close the meeting about '#{meeting.topic}'. The target said nothing. Be dramatic. 'Meeting over. Very productive. For me.'"
    )

    post_to_channel(meeting.channel_id, DunderMifflinBot.Characters.Michael, text)
    Meetings.update_status(meeting.id, "timeout")
  end

  defp schedule_next(meeting_id, step, locale, opts \\ []) do
    delay = Keyword.get(opts, :delay, @step_delay)

    %{"meeting_id" => meeting_id, "step" => step, "locale" => locale}
    |> __MODULE__.new(schedule_in: div(delay, 1000))
    |> Oban.insert!()
  end

  defp post_to_channel(channel_id, character_module, content) do
    Router.send_as_character(channel_id, character_module, content)
    Process.sleep(100)
  end

  defp locale_label("pt_BR"), do: "Brazilian Portuguese (pt-BR) only. Do not mix with English except unavoidable proper names"
  defp locale_label(_), do: "English only. Do not mix with Portuguese except unavoidable proper names"
end
