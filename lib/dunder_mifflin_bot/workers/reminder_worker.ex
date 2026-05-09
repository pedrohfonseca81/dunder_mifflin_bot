defmodule DunderMifflinBot.Workers.ReminderWorker do
  use Oban.Worker, queue: :reminders, max_attempts: 3

  alias DunderMifflinBot.Characters.Character
  alias DunderMifflinBot.AI.OpenAI

  @impl true
  def perform(%Oban.Job{
        args: %{
          "user_id" => user_id,
          "channel_id" => channel_id,
          "message" => message,
          "locale" => locale
        }
      }) do
    char = Character.random_characters(1) |> List.first()
    char_name = char |> Module.split() |> List.last()

    system = char.system_prompt() <> "\n\nIMPORTANT: Respond in #{locale_label(locale)}."

    {:ok, delivery} =
      OpenAI.complete(
        system,
        "Deliver this reminder to <@#{user_id}>: '#{message}'. Stay in character."
      )

    Nostrum.Api.Message.create(channel_id, "⏰ **REMINDER** — <@#{user_id}>\n**#{char_name}:** #{delivery}")

    :ok
  end

  defp locale_label("pt_BR"), do: "Brazilian Portuguese (pt-BR) only. Do not mix with English except unavoidable proper names"
  defp locale_label(_), do: "English only. Do not mix with Portuguese except unavoidable proper names"
end
