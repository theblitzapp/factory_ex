defmodule ExFactoryTest do
  use ExUnit.Case
  doctest ExFactory

  test "greets the world" do
    assert ExFactory.hello() == :world
  end
end
