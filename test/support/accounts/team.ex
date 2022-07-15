defmodule FactoryEx.Support.Accounts.Team do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias FactoryEx.Support.Accounts.{User, Team, TeamOrganization}

  schema "teams" do
    field :name, :string

    has_many :users, User
    belongs_to :team_organization, TeamOrganization
  end

  @required_params [:name]

  def changeset(%Team{} = user, attrs \\ %{}) do
    user
      |> cast(attrs, @required_params)
      |> validate_required(@required_params)
  end
end


