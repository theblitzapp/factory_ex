defmodule FactoryEx.Support.Accounts.Label do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias FactoryEx.Support.Accounts.Label

  schema "account_labels" do
    field :label, :string
  end

  @required_params [:label]

  def changeset(%Label{} = user, attrs \\ %{}) do
    user
      |> cast(attrs, @required_params)
      |> validate_required(@required_params)
  end
end



