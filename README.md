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

FactoryEx can also build relational data structures based on your Ecto Schemas. This feature is
used to work with associations as a whole and aims to reduce test boilerplate. For example,
if a Team has many Users, it can create the parameters and/or associations automatically for you.
If your goal is to simply add a new user to a team, then it is preferred to do so manually.

To create many associations you can specify a tuple of `{count, params}` which are expanded to a list
of params before building the factory. For example given a tuple of `{2, %{name: "John"}}` it will
expand to `[%{name: "John"}, %{name: "John"}]`. This can be added inside of lists or as values in
the map of parameters. You can also manually specify parameters per item when you want to create many
params and override specific values. For example given three items if you wanted to customize the name
for one you can do `[%{}, %{name: "custom"}, %{}]` or `[{2, %{}}, %{name: "custom"}]`.

Let's take a look at an example:

```elixir
user_jane_doe = FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.User, %{name: "Jane Doe"})

team = FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.Team)

[random_user_one, random_user_two] = FactoryEx.insert_many!(2, FactoryEx.Support.Factory.Accounts.User, %{team_id: team.id})

FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.Label, %{user_id: random_user_one.id})
FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.Label, %{user_id: random_user_two.id})

user_john_doe = FactoryEx.insert!(FactoryEx.Support.Factory.Accounts.User, %{name: "John Doe", team_id: team.id})
```

This can also be written as:

```elixir
%{
  team: %{
    users: [user_john_doe, random_user_one, random_user_two]
  } = team
} = user_jane_doe =
  FactoryEx.insert!(
    FactoryEx.Support.Factory.Accounts.User,
    %{
      name: "Jane Doe",
      team: %{
        users: [%{name: "John Doe"}, {2, %{}}]
      }
    },
    relational: [:role, team: [users: [:labels]]]
  )
```

Note: While this can simplify the way you write boilerplate it comes with a tradeoff as it groups
more of your data together which can hurt readability as well as make selecting specific pieces of
data harder.

By default when building associations your params are put as associations on the changesets and will
be validated by your changeset validations. If this behavior is not desired you can set `validate`
to false and the params are deep converted to structs only.