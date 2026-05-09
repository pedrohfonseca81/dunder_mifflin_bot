defmodule DunderMifflinBot.AI.OpenAI do
  @model "gpt-4o-mini"
  @base_url "https://api.openai.com/v1"

  def complete(system_prompt, user_message) do
    call([
      %{role: "system", content: system_prompt},
      %{role: "user", content: user_message}
    ])
  end

  def complete_conversation(system_prompt, messages) do
    call([%{role: "system", content: system_prompt} | messages])
  end

  defp call(messages) do
    api_key = Application.get_env(:dunder_mifflin_bot, :openai_api_key)

    body = %{
      model: @model,
      messages: messages,
      max_tokens: 300,
      temperature: 0.9
    }

    case Req.post("#{@base_url}/chat/completions",
           json: body,
           headers: [
             {"Authorization", "Bearer #{api_key}"},
             {"Content-Type", "application/json"}
           ]
         ) do
      {:ok, %{status: 200, body: %{"choices" => [%{"message" => %{"content" => text}} | _]}}} ->
        {:ok, String.trim(text)}

      {:ok, %{status: status, body: body}} ->
        {:error, "OpenAI #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
