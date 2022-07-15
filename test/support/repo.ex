defmodule FactoryEx.Support.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :factory_ex,
    adapter: Ecto.Adapters.Postgres
end
