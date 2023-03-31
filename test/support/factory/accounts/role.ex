defmodule FactoryEx.Support.Factory.Accounts.Role do
  @moduledoc """
  Account Test Factory
  """
  @behaviour FactoryEx

  @impl FactoryEx
  def schema, do: FactoryEx.Support.Schema.Accounts.Role

  @impl FactoryEx
  def repo, do: FactoryEx.Support.Repo

  @impl FactoryEx
  def build(attrs \\ %{}) do
    Map.merge(%{code: Faker.Team.name()}, attrs)
  end
end
