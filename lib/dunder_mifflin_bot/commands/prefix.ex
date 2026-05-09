defmodule DunderMifflinBot.Commands.Prefix do
  alias DunderMifflinBot.Commands.Registry

  @prefix "dm!"

  def parse(message) do
    if String.starts_with?(message.content, @prefix) do
      content = String.slice(message.content, String.length(@prefix)..-1)
      [command_name | args_list] = String.split(content, " ", trim: true)

      case find_command(command_name) do
        nil ->
          nil

        cmd_spec ->
          args_map = parse_args(args_list, cmd_spec[:options] || [])
          
          %{
            mock: true,
            guild_id: message.guild_id,
            channel_id: message.channel_id,
            member: %{
              user_id: message.author.id,
              roles: (message.member && message.member.roles) || []
            },
            data: %{
              name: cmd_spec.name,
              # This is for character commands that don't use get_option but run_character
              # but wait, run_character doesn't use data.options directly, it uses get_option helper
              options: [] 
            },
            args: args_map
          }
      end
    else
      nil
    end
  end

  defp find_command(name) do
    Enum.find(Registry.commands(), fn cmd ->
      cmd.name == name || (cmd.name_localizations && cmd.name_localizations["pt-BR"] == name)
    end)
  end

  defp parse_args([], _options), do: %{}

  defp parse_args(args_list, options) do
    # Simple positional mapping for now
    options
    |> Enum.zip(args_list)
    |> Enum.map(fn {opt, val} ->
      clean_val =
        case opt.type do
          6 -> # USER
            case Regex.run(~r/<@!?(\d+)>/, val) do
              [_, id] -> id
              _ -> val
            end
          4 -> # INTEGER
            case Integer.parse(val) do
              {i, _} -> i
              _ -> val
            end
          _ -> 
            # If it's the last option and we have more args, join them
            if opt == List.last(options) do
              Enum.join([val | tl(Enum.drop_while(args_list, &(&1 != val)))], " ")
            else
              val
            end
        end
      {opt.name, clean_val}
    end)
    |> Map.new()
  end
end
