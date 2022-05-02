defmodule FactoryExTest do
  use ExUnit.Case
  doctest FactoryEx

  test "greets the world" do
    assert FactoryEx.hello() == :world
  end
end
