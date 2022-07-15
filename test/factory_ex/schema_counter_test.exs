defmodule FactoryEx.SchemaCounterTest do
  use ExUnit.Case

  setup_all do
    :ok = FactoryEx.SchemaCounter.start()

    %{}
  end

  doctest FactoryEx.SchemaCounter
end
