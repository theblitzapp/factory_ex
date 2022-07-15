defmodule FactoryExTest do
  use ExUnit.Case

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

    def repo, do: FactoryEx.Support.Repo

    def build(params \\ %{}) do
      default = %{
        foo: 21,
        bar: 42
      }

      Map.merge(default, params)
    end
  end

  setup_all do
    {:ok, _} = Ecto.Adapters.Postgres.ensure_all_started(FactoryEx.Support.Repo, :temporary)

    _ = Ecto.Adapters.Postgres.storage_down(FactoryEx.Support.Repo.config())
    :ok = Ecto.Adapters.Postgres.storage_up(FactoryEx.Support.Repo.config())

    {:ok, _pid} = FactoryEx.Support.Repo.start_link()

    %{}
  end

  doctest FactoryEx

  test "can generate a factory" do
    assert %{foo: 21, bar: 42} = TestFactory.build()
    assert %{foo: 21, bar: 10} = TestFactory.build(%{bar: 10})
  end

  test "can insert a factory" do
    assert %MySchema{foo: 21, bar: 42} = FactoryEx.insert!(TestFactory)
    assert %MySchema{foo: 21, bar: 10} = FactoryEx.insert!(TestFactory, bar: 10)
  end
end
