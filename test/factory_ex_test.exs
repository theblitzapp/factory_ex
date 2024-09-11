defmodule FactoryExTest do
  use FactoryEx.DataCase
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
      field(:foo, :integer)
      field(:bar, :integer)
      field(:foo_bar_baz, :integer)
    end

    @required_params [:foo, :bar]
    @available_params [:foo_bar_baz | @required_params]

    def changeset(%__MODULE__{} = user, attrs \\ %{}) do
      user
      |> cast(attrs, @available_params)
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
        bar: 42,
        foo_bar_baz: 11
      }

      Map.merge(default, params)
    end
  end

  test "can generate a factory" do
    # assert %MySchema{foo: 21, bar: 42} = FactoryEx.insert!(TestFactory)
    # assert %MySchema{foo: 21, bar: 10} = FactoryEx.insert!(TestFactory, bar: 10)

    assert %MySchema{foo: 21, bar: 42, foo_bar_baz: 11} = FactoryEx.build(TestFactory)
    assert %MySchema{foo: 21, bar: 10, foo_bar_baz: 11} = FactoryEx.build(TestFactory, %{bar: 10})

    assert %{foo: 21, bar: 42, foo_bar_baz: 11} = FactoryEx.build_params(TestFactory)
    assert %{foo: 21, bar: 10, foo_bar_baz: 11} = FactoryEx.build_params(TestFactory, %{bar: 10})
  end

  test "can generate many factories" do
    assert [_, _] = FactoryEx.build_many_params(2, TestFactory)
  end

  test "can generate a factory with string keys" do
    assert %{
             "foo" => 21,
             "bar" => 42,
             "foo_bar_baz" => 11
           } = FactoryEx.build_params(TestFactory, %{}, keys: :string)
  end

  test "can generate a factory with camelCase keys" do
    assert %{
             "foo" => 21,
             "bar" => 42,
             "fooBarBaz" => 11
           } = FactoryEx.build_params(TestFactory, %{}, keys: :camel_string)
  end

  test "can build ecto schema associations with changeset validation" do
    assert %FactoryEx.Support.Schema.Accounts.TeamOrganization{
            teams: [
              %{
                users: [
                  %FactoryEx.Support.Schema.Accounts.User{
                    role: %FactoryEx.Support.Schema.Accounts.Role{},
                    labels: [%FactoryEx.Support.Schema.Accounts.Label{}]
                  }
                ]
              }
            ]
          } =
          FactoryEx.build(
            FactoryEx.Support.Factory.Accounts.TeamOrganization,
            %{},
            relational: [teams: [users: [:role, :labels]]]
          )
  end

  test "can build ecto schema associations without changeset validation" do
    assert %FactoryEx.Support.Schema.Accounts.TeamOrganization{
            teams: [
              %{
                users: [
                  %FactoryEx.Support.Schema.Accounts.User{
                    role: %FactoryEx.Support.Schema.Accounts.Role{},
                    labels: [%FactoryEx.Support.Schema.Accounts.Label{}]
                  }
                ]
              }
            ]
          } =
          FactoryEx.build(
            FactoryEx.Support.Factory.Accounts.TeamOrganization,
            %{},
            relational: [teams: [users: [:role, :labels]]],
            validate: false
          )
  end

  test "can insert" do
    assert %FactoryEx.Support.Schema.Accounts.User{} =
      FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.User)

    assert %FactoryEx.Support.Schema.Accounts.TeamOrganization{
        teams: [
          %{
            users: [
              %FactoryEx.Support.Schema.Accounts.User{
                role: %FactoryEx.Support.Schema.Accounts.Role{},
                labels: [%FactoryEx.Support.Schema.Accounts.Label{}]
              }
            ]
          }
        ]
      } =
      FactoryEx.insert!(
        FactoryEx.Support.Factory.Accounts.TeamOrganization,
        %{},
        relational: [teams: [users: [:role, :labels]]]
      )

    assert %FactoryEx.Support.Schema.Accounts.TeamOrganization{
      teams: [
        %{
          users: [
            %FactoryEx.Support.Schema.Accounts.User{},
            %FactoryEx.Support.Schema.Accounts.User{}
          ]
        }
      ]
    } =
    FactoryEx.insert!(
      FactoryEx.Support.Factory.Accounts.TeamOrganization,
      %{teams: [%{users: {2, %{}}}]},
      relational: [teams: [:users]]
    )
  end
end
