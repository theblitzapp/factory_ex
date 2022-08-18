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
# For getting a default parameter map.
FactoryEx.build(MyFactory)

# For getting a default parameter map with a modification.
FactoryEx.build(MyFactory, foo: 42)

# For getting a default parameter map and not validating the changeset
FactoryEx.build(MyFactory, [foo: 42], validate?: false)

# For inserting a default schema.
FactoryEx.insert!(MyFactory)

# For inserting a default schema with a modification.
FactoryEx.insert!(MyFactory, foo: 42)
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
