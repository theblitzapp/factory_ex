defmodule FactoryEx.Support.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string

      add :team_organization_id, references(:team_organizations, on_delete: :delete_all)
    end
  end
end
