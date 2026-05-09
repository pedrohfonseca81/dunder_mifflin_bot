defmodule DunderMifflinBot.CharacterSession do
  use GenServer

  @ttl 60_000
  @max_history 10

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def start_session(channel_id, user_id, character, locale, initial_reply) do
    GenServer.call(__MODULE__, {:start, channel_id, user_id, character, locale, initial_reply})
  end

  def get_session(channel_id, user_id) do
    GenServer.call(__MODULE__, {:get, channel_id, user_id})
  end

  def add_exchange(channel_id, user_id, user_msg, reply) do
    GenServer.cast(__MODULE__, {:exchange, channel_id, user_id, user_msg, reply})
  end

  def end_session(channel_id, user_id) do
    GenServer.cast(__MODULE__, {:end, channel_id, user_id})
  end

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:start, channel_id, user_id, character, locale, initial_reply}, _from, state) do
    key = {channel_id, user_id}
    if old = state[key], do: Process.cancel_timer(old.timer)
    timer = Process.send_after(self(), {:expire, key}, @ttl)
    session = %{
      character: character,
      locale: locale,
      history: [%{role: "assistant", content: initial_reply}],
      timer: timer
    }
    {:reply, :ok, Map.put(state, key, session)}
  end

  @impl true
  def handle_call({:get, channel_id, user_id}, _from, state) do
    {:reply, Map.get(state, {channel_id, user_id}), state}
  end

  @impl true
  def handle_cast({:exchange, channel_id, user_id, user_msg, reply}, state) do
    key = {channel_id, user_id}
    case state[key] do
      nil ->
        {:noreply, state}
      session ->
        history =
          (session.history ++ [%{role: "user", content: user_msg}, %{role: "assistant", content: reply}])
          |> Enum.take(-@max_history)
        {:noreply, Map.put(state, key, %{session | history: history})}
    end
  end

  @impl true
  def handle_cast({:end, channel_id, user_id}, state) do
    key = {channel_id, user_id}
    if old = state[key], do: Process.cancel_timer(old.timer)
    {:noreply, Map.delete(state, key)}
  end

  @impl true
  def handle_info({:expire, key}, state) do
    case Map.pop(state, key) do
      {nil, state} ->
        {:noreply, state}
      {%{character: char, locale: locale}, new_state} ->
        {channel_id, _} = key
        spawn(fn ->
          system = DunderMifflinBot.Characters.Character.build_prompt(char, locale)
          case DunderMifflinBot.AI.OpenAI.complete(system, "The conversation time is up. Say a brief in-character goodbye. Under 100 characters.") do
            {:ok, farewell} -> DunderMifflinBot.Commands.Router.send_as_character(channel_id, char, farewell)
            _ -> :ok
          end
        end)
        {:noreply, new_state}
    end
  end
end
