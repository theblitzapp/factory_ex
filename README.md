# FactoryEx

[![Test](https://github.com/theblitzapp/factory_ex/actions/workflows/test-actions.yml/badge.svg)](https://github.com/theblitzapp/factory_ex/actions/workflows/test-actions.yml)
[![Hex version badge](https://img.shields.io/hexpm/v/factory_ex.svg)](https://hex.pm/packages/factory_ex)

### Installation

[Available in Hex](https://hex.pm/docs/publish), the package can be installed
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

# For inserting a default schema.
FactoryEx.insert!(MyFactory)

# For inserting a default schema with a modification.
FactoryEx.insert!(MyFactory, foo: 42)
```

