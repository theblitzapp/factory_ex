defmodule FactoryEx.Support.Repo.Migrations.CreateAccountUsers do
  use Ecto.Migration

  def change do
    create table(:account_users) do
      add :name, :string
      add :age, :integer
      add :email, :string
      add :email_updated_at, :utc_datetime_usec
      add :location, :string
      add :gender, :string
      add :birthday, :date

      add :role_id, references(:account_roles, on_delete: :delete_all)
      add :team_id, references(:teams, on_delete: :delete_all)

      timestamps()
    end
  end
end
