defmodule DunderMifflinBot.Commands.Router do
  use Gettext, backend: DunderMifflinBot.Gettext

  alias DunderMifflinBot.Commands.{Permissions, Moderation, Social, Utility, Economy, Superadmin}
  alias DunderMifflinBot.Characters.Character
  alias DunderMifflinBot.Economy.Wallet
  alias DunderMifflinBot.{Servers, CharacterSession}

  def handle(%{data: %{name: name}} = interaction) do
    locale = Servers.get_language(interaction.guild_id)
    Gettext.put_locale(DunderMifflinBot.Gettext, locale)
    dispatch(name, interaction, locale)
  end

  # Character commands
  defp dispatch("michael", interaction, locale) do
    subject = get_option(interaction, "subject")
    run_character(interaction, DunderMifflinBot.Characters.Michael, %{subject: subject}, "michael", locale)
  end

  defp dispatch("dwight", interaction, locale) do
    target = get_user_mention(interaction, "person")
    reason = get_option(interaction, "reason")
    run_character(interaction, DunderMifflinBot.Characters.Dwight, %{target: target, reason: reason}, "dwight", locale)
  end

  defp dispatch("jim", interaction, locale) do
    messages = fetch_recent_messages(interaction.channel_id)
    run_character(interaction, DunderMifflinBot.Characters.Jim, %{messages: messages}, "jim", locale)
  end

  defp dispatch("kevin", interaction, locale) do
    topic = get_option(interaction, "topic")
    run_character(interaction, DunderMifflinBot.Characters.Kevin, %{topic: topic}, "kevin", locale)
  end

  defp dispatch("creed", interaction, locale) do
    run_character(interaction, DunderMifflinBot.Characters.Creed, %{}, "creed", locale)
  end

  defp dispatch("stanley", interaction, locale) do
    messages = fetch_recent_messages(interaction.channel_id)
    run_character(interaction, DunderMifflinBot.Characters.Stanley, %{messages: messages}, "stanley", locale)
  end

  defp dispatch("toby", interaction, locale) do
    with :ok <- Permissions.check(interaction, :everyone),
         target = get_user_mention(interaction, "person"),
         reason = get_option(interaction, "reason"),
         {:ok, _} <- Wallet.debit(interaction.member.user_id, interaction.guild_id, 5, "toby") do
      Utility.handle_toby(interaction, target, reason, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
      {:error, :insufficient_funds} -> reply_ephemeral(interaction, insufficient_funds_msg())
    end
  end

  defp dispatch("andy", interaction, locale) do
    subject = get_option(interaction, "subject")
    run_character(interaction, DunderMifflinBot.Characters.Andy, %{subject: subject}, "andy", locale)
  end

  defp dispatch("oscar", interaction, locale) do
    subject = get_option(interaction, "subject")
    run_character(interaction, DunderMifflinBot.Characters.Oscar, %{subject: subject}, "oscar", locale)
  end

  defp dispatch("angela", interaction, locale) do
    target = get_user_mention(interaction, "person")
    run_character(interaction, DunderMifflinBot.Characters.Angela, %{target: target}, "angela", locale)
  end

  # Social
  defp dispatch("meeting", interaction, locale) do
    with :ok <- Permissions.check(interaction, :everyone),
         target = get_user_id(interaction, "person"),
         topic = get_option(interaction, "topic"),
         {:ok, _} <- Wallet.debit(interaction.member.user_id, interaction.guild_id, 15, "meeting") do
      Social.handle_meeting(interaction, target, topic, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
      {:error, :insufficient_funds} -> reply_ephemeral(interaction, insufficient_funds_msg())
    end
  end

  defp dispatch("trial", interaction, locale) do
    with :ok <- Permissions.check(interaction, :everyone),
         target = get_user_id(interaction, "person"),
         reason = get_option(interaction, "reason"),
         {:ok, _} <- Wallet.debit(interaction.member.user_id, interaction.guild_id, 10, "trial") do
      Social.handle_trial(interaction, target, reason, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
      {:error, :insufficient_funds} -> reply_ephemeral(interaction, insufficient_funds_msg())
    end
  end

  defp dispatch("alliance", interaction, locale) do
    with :ok <- Permissions.check(interaction, :everyone) do
      target = get_user_mention(interaction, "person")
      Social.handle_alliance(interaction, target, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
    end
  end

  defp dispatch("vote", interaction, locale) do
    with :ok <- Permissions.check(interaction, :everyone) do
      opt1 = get_option(interaction, "option1")
      opt2 = get_option(interaction, "option2")
      Social.handle_vote(interaction, opt1, opt2, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
    end
  end

  defp dispatch("dundie", interaction, locale) do
    with :ok <- Permissions.check(interaction, :everyone),
         target_id = get_user_id(interaction, "person"),
         category = get_option(interaction, "category"),
         {:ok, _} <- Wallet.debit(interaction.member.user_id, interaction.guild_id, 5, "dundie") do
      Social.handle_dundie(interaction, target_id, category, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
      {:error, :insufficient_funds} -> reply_ephemeral(interaction, insufficient_funds_msg())
    end
  end

  # Utility
  defp dispatch("summary", interaction, locale) do
    with :ok <- Permissions.check(interaction, :everyone),
         {:ok, _} <- Wallet.debit(interaction.member.user_id, interaction.guild_id, 8, "summary") do
      Utility.handle_summary(interaction, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
      {:error, :insufficient_funds} -> reply_ephemeral(interaction, insufficient_funds_msg())
    end
  end

  defp dispatch("translate", interaction, locale) do
    with :ok <- Permissions.check(interaction, :everyone),
         text = get_option(interaction, "text"),
         language = get_option(interaction, "language"),
         {:ok, _} <- Wallet.debit(interaction.member.user_id, interaction.guild_id, 5, "translate") do
      Utility.handle_translate(interaction, text, language, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
      {:error, :insufficient_funds} -> reply_ephemeral(interaction, insufficient_funds_msg())
    end
  end

  defp dispatch("reminder", interaction, locale) do
    with :ok <- Permissions.check(interaction, :everyone),
         target_id = get_user_id(interaction, "person"),
         time_str = get_option(interaction, "time"),
         message = get_option(interaction, "message"),
         {:ok, _} <- Wallet.debit(interaction.member.user_id, interaction.guild_id, 3, "reminder") do
      Utility.handle_reminder(interaction, target_id, time_str, message, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
      {:error, :insufficient_funds} -> reply_ephemeral(interaction, insufficient_funds_msg())
    end
  end

  defp dispatch("birthday", interaction, locale) do
    date_str = get_option(interaction, "date")
    Utility.handle_birthday(interaction, date_str, locale)
  end

  defp dispatch("help", interaction, locale) do
    Utility.handle_help(interaction, locale)
  end

  # Economy
  defp dispatch("shift", interaction, locale) do
    Economy.handle_shift(interaction, locale)
  end

  defp dispatch("balance", interaction, locale) do
    Economy.handle_balance(interaction, locale)
  end

  defp dispatch("pay", interaction, locale) do
    target_id = get_user_id(interaction, "person")
    amount = get_option_integer(interaction, "amount")
    Economy.handle_pay(interaction, target_id, amount, locale)
  end


  defp dispatch("store", interaction, locale) do
    Economy.handle_store(interaction, locale)
  end

  defp dispatch("profile", interaction, locale) do
    target_id = get_user_id(interaction, "person") || interaction.member.user_id
    Economy.handle_profile(interaction, target_id, locale)
  end

  defp dispatch("dashboard", interaction, locale) do
    Economy.handle_dashboard(interaction, locale)
  end

  # Moderation
  defp dispatch("warn", interaction, locale) do
    with :ok <- Permissions.check(interaction, :moderator) do
      target_id = get_user_id(interaction, "person")
      reason = get_option(interaction, "reason")
      Moderation.handle_warn(interaction, target_id, reason, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
    end
  end

  defp dispatch("mute", interaction, locale) do
    with :ok <- Permissions.check(interaction, :moderator) do
      target_id = get_user_id(interaction, "person")
      time_str = get_option(interaction, "time")
      reason = get_option(interaction, "reason")
      Moderation.handle_mute(interaction, target_id, time_str, reason, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
    end
  end

  defp dispatch("timeout", interaction, locale) do
    with :ok <- Permissions.check(interaction, :moderator) do
      target_id = get_user_id(interaction, "person")
      time_str = get_option(interaction, "time")
      reason = get_option(interaction, "reason")
      Moderation.handle_timeout(interaction, target_id, time_str, reason, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
    end
  end

  defp dispatch("kick", interaction, locale) do
    with :ok <- Permissions.check(interaction, :admin) do
      target_id = get_user_id(interaction, "person")
      reason = get_option(interaction, "reason")
      Moderation.handle_kick(interaction, target_id, reason, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
    end
  end

  defp dispatch("ban", interaction, locale) do
    with :ok <- Permissions.check(interaction, :admin) do
      target_id = get_user_id(interaction, "person")
      reason = get_option(interaction, "reason")
      Moderation.handle_ban(interaction, target_id, reason, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
    end
  end

  defp dispatch("logs", interaction, locale) do
    with :ok <- Permissions.check(interaction, :moderator) do
      Moderation.handle_logs(interaction, locale)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
    end
  end

  defp dispatch("rules", interaction, locale) do
    content = get_option(interaction, "content")

    if content do
      with :ok <- Permissions.check(interaction, :moderator) do
        Moderation.handle_rules_set(interaction, content, locale)
      else
        {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
      end
    else
      Moderation.handle_rules_view(interaction, locale)
    end
  end

  defp dispatch("config", interaction, _locale) do
    with :ok <- Permissions.check(interaction, :admin) do
      Utility.handle_config_panel(interaction)
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
    end
  end

  defp dispatch("superadmin", interaction, _locale) do
    with :ok <- Permissions.check(interaction, :superadmin) do
      case get_subcommand(interaction) do
        "ping" -> Superadmin.handle_ping(interaction)
        "sync_commands" -> Superadmin.handle_sync_commands(interaction)
        "owners" -> Superadmin.handle_owners(interaction)
        "grant_sb" ->
          target_id = get_subcommand_option(interaction, "person")
          amount = get_subcommand_option_integer(interaction, "amount")
          Superadmin.handle_grant_sb(interaction, target_id, amount)

        _ -> reply_ephemeral(interaction, "Unknown superadmin subcommand")
      end
    else
      {:error, :forbidden} -> reply_ephemeral(interaction, Permissions.forbidden_reply(interaction))
    end
  end

  defp dispatch(unknown, interaction, _locale) do
    reply_ephemeral(interaction, "Unknown command: #{unknown}")
  end

  # Helpers

  @character_display_names %{
    "Michael" => "Michael Scott",
    "Dwight"  => "Dwight Schrute",
    "Jim"     => "Jim Halpert",
    "Kevin"   => "Kevin Malone",
    "Creed"   => "Creed Bratton",
    "Stanley" => "Stanley Hudson",
    "Toby"    => "Toby Flenderson",
    "Andy"    => "Andy Bernard",
    "Oscar"   => "Oscar Martinez",
    "Angela"  => "Angela Martin"
  }

  @character_avatars %{
    "Michael" => "https://static.wikia.nocookie.net/theoffice/images/b/be/Character_-_MichaelScott.PNG/revision/latest?cb=20200413224550",
    "Dwight"  => "https://static.wikia.nocookie.net/theoffice/images/c/c5/Dwight_.jpg/revision/latest?cb=20170701082424",
    "Jim"     => "https://static.wikia.nocookie.net/theoffice/images/e/e9/Character_-_JimHalpert.PNG/revision/latest?cb=20200414162003",
    "Kevin"   => "https://static.wikia.nocookie.net/theoffice/images/b/b2/2009Kevincropped.PNG/revision/latest/scale-to-width-down/1000?cb=20170701083657",
    "Creed"   => "https://static.wikia.nocookie.net/theoffice/images/2/20/2009Creed.jpg/revision/latest/scale-to-width-down/1000?cb=20170701085348",
    "Stanley" => "https://static.wikia.nocookie.net/theoffice/images/2/23/Stanley_Hudson.jpg/revision/latest/scale-to-width-down/1000?cb=20170701085445",
    "Toby"    => "https://static.wikia.nocookie.net/theoffice/images/4/4a/TobyFlenderson.jpg/revision/latest/scale-to-width-down/1000?cb=20230826001012",
    "Andy"    => "https://static.wikia.nocookie.net/theoffice/images/2/20/C0164512-C4C2-485C-9CB6-85B31F642090.jpeg/revision/latest/scale-to-width-down/1000?cb=20200103213101",
    "Oscar"   => "https://static.wikia.nocookie.net/theoffice/images/2/25/Oscar_Martinez.jpg/revision/latest/scale-to-width-down/1000?cb=20170701085818",
    "Angela"  => "https://static.wikia.nocookie.net/theoffice/images/0/0b/Angela_Martin.jpg/revision/latest/scale-to-width-down/1000?cb=20170701090232"
  }

  defp run_character(interaction, character_module, context, command, locale) do
    user_id = interaction.member.user_id
    server_id = interaction.guild_id
    cost = character_module.cost()

    Nostrum.Api.Interaction.create_response(interaction, %{type: 5, data: %{flags: 64}})

    with :ok <- Permissions.check(interaction, :everyone),
         {:ok, _} <- Wallet.debit(user_id, server_id, cost, command),
         {:ok, response} <- Character.generate(character_module, context, locale) do
      send_as_character(interaction.channel_id, character_module, response)
      CharacterSession.start_session(interaction.channel_id, user_id, character_module, locale, response)
      char_key = character_module |> Module.split() |> List.last()
      name = Map.get(@character_display_names, char_key, char_key)
      edit_response(interaction, "💬 **#{name}** disponível por 1 minuto. Custo: 2 SB/mensagem.")
    else
      {:error, :forbidden} -> edit_response(interaction, Permissions.forbidden_reply(interaction))
      {:error, :insufficient_funds} -> edit_response(interaction, insufficient_funds_msg())
      {:error, reason} -> edit_response(interaction, "Error: #{inspect(reason)}")
    end
  end

  def send_as_character(channel_id, character_module, content, opts \\ %{}) do
    char_key = character_module |> Module.split() |> List.last()
    name = Map.get(@character_display_names, char_key, char_key)
    avatar = Map.get(@character_avatars, char_key)
    components = Map.get(opts, :components, [])

    base_args = %{content: content, username: name, avatar_url: avatar}

    args =
      if components == [] do
        base_args
      else
        Map.put(base_args, :components, components)
      end

    case Nostrum.Api.Webhook.create(channel_id, %{name: "Dunder Mifflin"}) do
      {:ok, %{id: wh_id, token: wh_token}} ->
        Nostrum.Api.Webhook.execute(wh_id, wh_token, args)
        Nostrum.Api.Webhook.delete(wh_id)

      _ ->
        fallback_message =
          if components == [] do
            "**#{name}:** #{content}"
          else
            %{content: "**#{name}:** #{content}", components: components}
          end

        Nostrum.Api.Message.create(channel_id, fallback_message)
    end
  end

  def defer(interaction) do
    Nostrum.Api.Interaction.create_response(interaction, %{type: 5})
  end

  def defer_ephemeral(interaction) do
    Nostrum.Api.Interaction.create_response(interaction, %{type: 5, data: %{flags: 64}})
  end

  def delete_response(interaction) do
    Nostrum.Api.Interaction.delete_response(interaction)
  end

  def edit_response(interaction, content) do
    Nostrum.Api.Interaction.edit_response(interaction, %{content: content})
  end

  def reply(interaction, content) do
    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 4,
      data: %{content: content}
    })
  end

  def reply_ephemeral(interaction, content) do
    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 4,
      data: %{content: content, flags: 64}
    })
  end

  def reply_with_components(interaction, content, components) do
    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 4,
      data: %{content: content, components: components}
    })
  end

  defp get_option(interaction, name) do
    options = get_in(interaction, [Access.key(:data), Access.key(:options)]) || []
    opt = Enum.find(options, &(&1.name == name))
    opt && opt.value
  end

  defp get_subcommand(interaction) do
    options = get_in(interaction, [Access.key(:data), Access.key(:options)]) || []

    case options do
      [%{type: 1, name: subcommand} | _] -> subcommand
      _ -> nil
    end
  end

  defp get_subcommand_option(interaction, name) do
    options = get_in(interaction, [Access.key(:data), Access.key(:options)]) || []

    case options do
      [%{type: 1, options: sub_opts} | _] when is_list(sub_opts) ->
        opt = Enum.find(sub_opts, &(&1.name == name))
        opt && opt.value

      _ ->
        nil
    end
  end

  defp get_subcommand_option_integer(interaction, name) do
    case get_subcommand_option(interaction, name) do
      nil -> nil
      v when is_integer(v) -> v
      v -> String.to_integer(to_string(v))
    end
  end

  defp get_option_integer(interaction, name) do
    case get_option(interaction, name) do
      nil -> nil
      v when is_integer(v) -> v
      v -> String.to_integer(to_string(v))
    end
  end

  defp get_user_id(interaction, name), do: get_option(interaction, name)

  defp get_user_mention(interaction, name) do
    id = get_option(interaction, name)
    if id, do: "<@#{id}>", else: nil
  end

  defp fetch_recent_messages(channel_id) do
    case Nostrum.Api.Channel.messages(channel_id, 10) do
      {:ok, messages} ->
        messages
        |> Enum.reverse()
        |> Enum.map(fn m -> "#{m.author.username}: #{m.content}" end)

      _ ->
        []
    end
  end

  defp insufficient_funds_msg do
    dgettext("economy", "insufficient_funds")
  end
end
