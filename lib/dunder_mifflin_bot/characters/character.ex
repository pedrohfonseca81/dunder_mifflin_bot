defmodule DunderMifflinBot.Characters.Character do
  @callback system_prompt() :: String.t()
  @callback format_context(map()) :: String.t()
  @callback cost() :: non_neg_integer()

  def generate(character_module, context, locale) do
    system = build_prompt(character_module, locale)
    user_message = character_module.format_context(context)
    DunderMifflinBot.AI.OpenAI.complete(system, user_message)
  end

  def build_prompt(character_module, locale) do
    character_module.system_prompt() <>
      "\n\nIMPORTANT: Respond in #{locale_label(locale)}. " <>
      "Adapt slang, idioms and cultural references to feel natural in #{locale_label(locale)}."
  end

  defp locale_label("pt_BR"), do: "Brazilian Portuguese (pt-BR) only. Do not mix with English except unavoidable proper names"
  defp locale_label("en"), do: "English only. Do not mix with Portuguese except unavoidable proper names"
  defp locale_label(other), do: other

  def all_characters do
    [
      DunderMifflinBot.Characters.Michael,
      DunderMifflinBot.Characters.Dwight,
      DunderMifflinBot.Characters.Jim,
      DunderMifflinBot.Characters.Kevin,
      DunderMifflinBot.Characters.Creed,
      DunderMifflinBot.Characters.Stanley,
      DunderMifflinBot.Characters.Toby,
      DunderMifflinBot.Characters.Andy,
      DunderMifflinBot.Characters.Oscar,
      DunderMifflinBot.Characters.Angela
    ]
  end

  def random_characters(count \\ 2) do
    all_characters() |> Enum.shuffle() |> Enum.take(count)
  end
end
