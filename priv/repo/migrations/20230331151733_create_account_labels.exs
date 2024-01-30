defmodule FactoryEx.Support.Repo.Migrations.CreateAccountLabels do
  use Ecto.Migration

  def change do
    create table(:account_labels) do
      add :label, :text
    end
  end
end
