defmodule FactoryEx.Support.Repo.Migrations.CreateAccountRoles do
  use Ecto.Migration

  def change do
    create table(:account_roles) do
      add :code, :string
    end
  end
end
