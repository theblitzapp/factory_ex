defmodule FactoryEx.Support.Repo.Migrations.CreateTeamOrganizations do
  use Ecto.Migration

  def change do
    create table(:team_organizations) do
      add :name, :string
    end
  end
end
