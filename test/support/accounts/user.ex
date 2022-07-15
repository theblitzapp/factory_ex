defmodule FactoryEx.Support.Accounts.User do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2, update_change: 3, validate_length: 3]

  alias FactoryEx.Support.Accounts.{User, Role, Team, Label}

  @username_min 3
  @username_max 15
  @email_max_length 255

  schema "account_users" do
    field :name, :string
    field :email, :string
    field :email_updated_at, :utc_datetime_usec
    field :location, :string
    field :gender, :string
    field :birthday, :date

    belongs_to :role, Role
    belongs_to :team, Team

    many_to_many :labels, Label, join_through: "account_user_labels"

    timestamps(type: :utc_datetime_usec)
  end

  @required_params [:email]
  @available_params [
    :email_updated_at,
    :name,
    :birthday,
    :location,
    :gender | @required_params
  ]

  def changeset(%User{} = user, attrs \\ %{}) do
    user
      |> cast(attrs, @available_params)
      |> validate_required(@required_params)
      |> update_change(:location, &String.upcase/1)
      |> validate_length(:name, min: @username_min, max: @username_max)
      |> validate_length(:email, max: @email_max_length)
  end
end
