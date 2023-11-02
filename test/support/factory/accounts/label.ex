defmodule FactoryEx.Support.Factory.Accounts.Label do
  @moduledoc false
  @behaviour FactoryEx

  @impl FactoryEx
  def schema, do: FactoryEx.Support.Schema.Accounts.Label

  @impl FactoryEx
  def repo, do: FactoryEx.Support.Repo

  @impl FactoryEx
  def build(attrs \\ %{}) do
    Map.merge(%{label: Faker.Lorem.word()}, attrs)
  end
end
