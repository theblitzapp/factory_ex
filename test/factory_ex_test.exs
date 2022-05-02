defmodule FactoryExTest do
  use ExUnit.Case
  doctest FactoryEx

  defmodule MyRepo do
    @moduledoc false
    use Ecto.Repo,
      otp_app: :my_repo,
      adapter: Ecto.Adapters.Postgres
  end

  defmodule MySchema do
    use Ecto.Schema
    import Ecto.Changeset

    schema "my_schmeas" do
      field :foo, :integer
      field :bar, :integer
    end

    @required_params [:foo, :bar]

    def changeset(%__MODULE__{} = user, attrs \\ %{}) do
      user
        |> cast(attrs, @required_params)
        |> validate_required(@required_params)
    end
  end

  defmodule TestFactory do
    @behaviour FactoryEx

    def schema, do: MySchema

    def repo, do: MyRepo

    def build(params \\ %{}) do
      default = %{
        foo: 21,
        bar: 42
      }

      Map.merge(default, params)
    end
  end

  test "can generate a factory" do
    # assert %MySchema{foo: 21, bar: 42} = FactoryEx.insert!(TestFactory)
    # assert %MySchema{foo: 21, bar: 10} = FactoryEx.insert!(TestFactory, bar: 10)

    assert %{foo: 21, bar: 42} = TestFactory.build()
    assert %{foo: 21, bar: 10} = TestFactory.build(%{bar: 10})
  end
end
