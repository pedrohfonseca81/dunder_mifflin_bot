defmodule DunderMifflinBot.Commands.Permissions do
  import Bitwise
  use Gettext, backend: DunderMifflinBot.Gettext

  alias DunderMifflinBot.Servers

  def check(_interaction, :everyone), do: :ok

  def check(interaction, :moderator) do
    perms = get_member_permissions(interaction)

    if has_any_flag?(perms, [:manage_messages, :moderate_members, :administrator]),
      do: :ok,
      else: {:error, :forbidden}
  end

  def check(interaction, :admin) do
    perms = get_member_permissions(interaction)

    if has_any_flag?(perms, [:administrator]),
      do: :ok,
      else: {:error, :forbidden}
  end

  def check(interaction, :owner) do
    guild = Nostrum.Cache.GuildCache.get!(interaction.guild_id)

    if interaction.member.user_id == guild.owner_id,
      do: :ok,
      else: {:error, :forbidden}
  end

  def check(interaction, :superadmin) do
    owners = Application.get_env(:dunder_mifflin_bot, :owners_ids, [])

    user_id =
      get_in(interaction, [Access.key(:member), Access.key(:user_id)]) ||
        get_in(interaction, [Access.key(:user), Access.key(:id)])

    if user_id in owners,
      do: :ok,
      else: {:error, :forbidden}
  end

  def forbidden_reply(interaction) do
    locale = Servers.get_language(interaction.guild_id)
    Gettext.put_locale(DunderMifflinBot.Gettext, locale)
    user = "<@#{interaction.member.user_id}>"
    dgettext("moderation", "forbidden", user: user)
  end

  defp get_member_permissions(interaction) do
    guild = Nostrum.Cache.GuildCache.get!(interaction.guild_id)
    member = interaction.member

    if member.user_id == guild.owner_id do
      0xFFFFFFFFFFFFFFFF
    else
      everyone_perms =
        case guild.roles[interaction.guild_id] do
          nil -> 0
          role -> role.permissions
        end

      member.roles
      |> Enum.reduce(everyone_perms, fn role_id, acc ->
        case guild.roles[role_id] do
          nil -> acc
          role -> bor(acc, role.permissions)
        end
      end)
    end
  end

  defp has_any_flag?(perms_int, flags) do
    Enum.any?(flags, fn flag -> flag_set?(perms_int, flag) end)
  end

  @discord_permissions %{
    administrator: 0x8,
    manage_messages: 0x2000,
    moderate_members: 0x10000000
  }

  defp flag_set?(perms_int, flag) do
    bit = Map.get(@discord_permissions, flag, 0)
    band(perms_int, bit) == bit
  end
end
