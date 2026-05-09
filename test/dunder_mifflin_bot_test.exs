defmodule DunderMifflinBotTest do
  use ExUnit.Case
  doctest DunderMifflinBot

  test "greets the world" do
    assert DunderMifflinBot.hello() == :world
  end
end
