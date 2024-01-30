# FactoryEx
[![Coverage](https://github.com/theblitzapp/factory_ex/actions/workflows/coverage.yml/badge.svg)](https://github.com/theblitzapp/factory_ex/actions/workflows/coverage.yml)
[![Test](https://github.com/theblitzapp/factory_ex/actions/workflows/test.yml/badge.svg)](https://github.com/theblitzapp/factory_ex/actions/workflows/test.yml)
[![Dialyzer](https://github.com/theblitzapp/factory_ex/actions/workflows/dialyzer.yml/badge.svg)](https://github.com/theblitzapp/factory_ex/actions/workflows/dialyzer.yml)
[![Credo](https://github.com/theblitzapp/factory_ex/actions/workflows/credo.yml/badge.svg)](https://github.com/theblitzapp/factory_ex/actions/workflows/credo.yml)
[![codecov](https://codecov.io/gh/theblitzapp/factory_ex/branch/master/graph/badge.svg?token=V0JJA5AZ1H)](https://codecov.io/gh/theblitzapp/factory_ex)
[![Hex version badge](https://img.shields.io/hexpm/v/factory_ex.svg)](https://hex.pm/packages/factory_ex)

### Installation

[Available in Hex](https://hex.pm/packages/factory_ex), the package can be installed
by adding `factory_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:factory_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be found at <https://hexdocs.pm/factory_ex>.

### Using
For defining your own factories just implement `schema/0`, `repo/0` and
`build/0` callback e.g:

```elixir
defmodule MyFactory do
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
```

And then using it in your tests as:

```elixir
# For getting a default parameter struct.
FactoryEx.build(MyFactory)

# For getting a default parameter struct with a modification.
FactoryEx.build(MyFactory, foo: 42)

# For getting a default parameter struct and not validating the changeset
FactoryEx.build(MyFactory, [foo: 42], validate?: false)

# For getting a default parameter map.
FactoryEx.build_params(MyFactory)

# For getting a default parameter map with a modification..
FactoryEx.build_params(MyFactory, foo: 10)

# For getting a default parameter map and not validating the changeset
FactoryEx.build_params(MyFactory, foo: 10, validate?: false)

# For getting multiple default parameter maps
FactoryEx.build_many_params(MyFactory, [foo: 42])

# For getting an invalid parameter maps
FactoryEx.build_invalid_params(MyFactory, [foo: 42])

# For inserting a default schema.
FactoryEx.insert!(MyFactory)

# For inserting a default schema with a modification.
FactoryEx.insert!(MyFactory, foo: 42)

# For inserting multiple default schema
FactoryEx.insert_many!(10, MyFactory, foo: 42)
```

### Using FactoryEx.SchemaCounter
In order to avoid duplicate data on fields and guarentee unique data, we can use
`FactoryEx.SchemaCounter` to generate unique integers to append to our fields.

For example our factory could look like the following:

```elixir
defmodule MyFactory do
  @behaviour FactoryEx

  def schema, do: MySchema

  def repo, do: MyRepo

  def build(params \\ %{}) do
    default = %{
      foo: FactoryEx.SchemaCounter.next("my_factory_foo"),
      bar: FactoryEx.SchemaCounter.next("my_factory_bar")
    }

    Map.merge(default, params)
  end
end
```

To utilize `FactoryEx.SchemaCounter`, we must call `FactoryEx.SchemaCounter.start()` in the `test/test_helper.exs` file.

### Generating Factories
FactoryEx comes with a helpful mix command to generate factories into our application

```bash
$ mix factory_ex.gen --repo FactoryEx.Support.Repo FactoryEx.Support.Accounts.User
$ mix factory_ex.gen --repo FactoryEx.Support.Repo FactoryEx.Support.{Accounts.{User,Role},Authentication.{Token,Session}}
```

To read more info run `mix factory_ex.gen`

### Build Relational Associations

FactoryEx makes it possible to create associated records with your factories. This is
similar to creating to creating records with Ecto.Changeset `cast_assoc` or `put_assoc`
with the addition of using your factory to generate the parameters. To use this feature
you must pass the `relational` option. The `relational` option accepts a list of keys
that map to associations, for example if a Team has many users you would pass
`[relational: [:users]]`:

```elixir
  FactoryEx.AssociationBuilder.build_params(
    FactoryEx.Support.Factory.Accounts.Team,
    %{},
    relational: [:users]
  )
```

The goal of this feature is to reduce boilerplate code in your test. In this example we
create a team with 3 users that each have a label and a role:

```elixir
setup do
  team = FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.Team)

  user_one = FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.User, %{team_id: team.id})
  FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.Label, %{user_id: user_one.id})
  FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.Role, %{user_id: user_one.id})

  user_two = FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.User, %{team_id: team.id})
  FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.Label, %{user_id: user_two.id})
  FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.Role, %{user_id: user_two.id})

  user_three = FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.User, %{team_id: team.id})
  FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.Label, %{user_id: user_three.id})
  FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.Role, %{user_id: user_three.id})
end
```

With the relational feature this can be written as:

```elixir
setup do
  team =
    FactoryEx.insert!(
      FactoryEx.Support.Factory.Accounts.Team,
      %{users: {3, %{}}},
      relational: [users: [:labels, :role]]
    )
end
```

You can create many associations by specifying a tuple of `{count, params}` which is expanded
to a list of params before building the params with a factory. For example if you pass a
tuple of `{2, %{name: "John"}}` it will be expanded to `[%{name: "John"}, %{name: "John"}]`.
The count tuples can be added as elements inside a list or as values in the map of
parameters. You can also manually add parameters which is useful for setting specific values
while creating a specific amount. For example given three items if you wanted to customize
the name for one you can do `[%{}, %{name: "custom"}, %{}]` or `[{2, %{}}, %{name: "custom"}]`.

By default parameters are validated by Ecto.Changeset. If this behavior is not desired you can
set the `validate` option to false which converts params to structs only.

While this can simplify the amount of boilerplate you have to write it comes with a trade off
of creating large complex objects that can hurt readability and/or make accessing specific
data harder.
