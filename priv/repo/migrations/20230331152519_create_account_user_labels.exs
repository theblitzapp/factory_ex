defmodule FactoryEx.Support.Repo.Migrations.CreateAccountUserLabels do
  use Ecto.Migration

  def change do
    create table(:account_user_labels) do
      add :user_id, references(:account_users, on_delete: :delete_all)
      add :label_id, references(:account_labels, on_delete: :delete_all)
    end
  end
end
