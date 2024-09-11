defmodule FactoryEx.Support.Factory.Accounts.User do
  @moduledoc false
  @behaviour FactoryEx

  @impl FactoryEx
  def schema, do: FactoryEx.Support.Schema.Accounts.User

  @impl FactoryEx
  def repo, do: FactoryEx.Support.Repo

  @impl FactoryEx
  def build(attrs \\ %{}) do
    Map.merge(%{
      name: Faker.Person.name(),
      email: Faker.Internet.email(),
      gender: Enum.random(~w[male female]),
      location: "someplace",
      birthday: ~D[1992-10-04]
    }, attrs)
  end
end
