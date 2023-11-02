defmodule FactoryEx.Support.Factory.Accounts.Team do
  @moduledoc false
  @behaviour FactoryEx

  @impl FactoryEx
  def schema, do: FactoryEx.Support.Schema.Accounts.Team

  @impl FactoryEx
  def repo, do: FactoryEx.Support.Repo

  @impl FactoryEx
  def build(attrs \\ %{}) do
    Map.merge(%{name: Faker.Company.name()}, attrs)
  end
end
