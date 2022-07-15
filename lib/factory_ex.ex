defmodule FactoryEx do
  @moduledoc """
  #{File.read!("./README.md")}
  """

  @doc """
  Callback that returns the schema module.
  """
  @callback schema() :: module()

  @doc """
  Callback that returns the schema's repo module.
  """
  @callback repo() :: module()

  @doc """
  Callback that returns a map with valid defaults for the schema.
  """
  @callback build(map()) :: map()

  @doc """
  Callback that returns a struct with valid defaults for the schema.
  """
  @callback build_struct(map()) :: struct()

  @optional_callbacks [build_struct: 1]

  @doc """
  Builds the parameters for a schema `changeset/2` function given the factory
  `module` and an optional list/map of `params`.

  ### Example

      iex> FactoryEx.build_params(TestFactory)
      %{foo: 21, bar: 42}

  """
  @spec build_params(module()) :: map()
  @spec build_params(module(), keyword() | map()) :: map()
  def build_params(module, params \\ %{})

  def build_params(module, params) when is_list(params) do
    build_params(module, Map.new(params))
  end

  def build_params(module, params) do
    params
    |> module.build()
    |> FactoryEx.Utils.deep_struct_to_map()
  end

  @doc """
  Builds a schema given the factory `module` and an optional
  list/map of `params`.

  ### Example

      iex> FactoryEx.build(TestFactory)
      %MySchema{foo: 21, bar: 42}

  """
  @spec build(module()) :: Ecto.Schema.t()
  @spec build(module(), keyword() | map()) :: Ecto.Schema.t()
  def build(module, params \\ %{})

  def build(module, params) when is_list(params) do
    build(module, Map.new(params))
  end

  def build(module, params) do
    struct!(module.schema(), module.build(params))
  end

  @doc """
  Inserts a schema given the factory `module` and an optional list/map of
  `params`. Fails on error.

  ### Example

      iex> factory = FactoryEx.insert!(TestFactory)
      %MySchema{foo: 21, bar: 42}
      iex> MyRepo.get(factory.id)
      factory

  """
  @spec insert!(module()) :: Ecto.Schema.t() | no_return()
  @spec insert!(module(), keyword() | map(), Keyword.t()) :: Ecto.Schema.t() | no_return()
  def insert!(module, params \\ %{}, options \\ [])

  def insert!(module, params, options) when is_list(params) do
    insert!(module, Map.new(params), options)
  end

  def insert!(module, params, options) do
    module
    |> build(params)
    |> module.repo().insert!(options)
  end

  @doc """
  Insert as many as `count` schemas given the factory `module` and an optional
  list/map of `params`.

  ### Example

      iex> FactoryEx.insert_many!(2, TestFactory)
      [%MySchema{foo: 21, bar: 42}, %MySchema{foo: 21, bar: 42}]

  """
  @spec insert_many!(pos_integer(), module()) :: [Ecto.Schema.t()]
  @spec insert_many!(pos_integer(), module(), keyword() | map()) :: [Ecto.Schema.t()]
  def insert_many!(count, module, params \\ %{}, options \\ []) when count > 0 do
    Enum.map(1..count, fn _ -> insert!(module, params, options) end)
  end

  @doc """
  Removes all the instances of a schema from the database given its factory
  `module`.

  ### Example

      iex> FactoryEx.insert!(TestFactory)
      %MySchema{foo: 21, bar: 42}
      iex> MyRepo.cleanup(TestFactory)
      {1, []}

  """
  @spec cleanup(module) :: {integer(), nil | [term()]}
  def cleanup(module, options \\ []) do
    module.repo().delete_all(module.schema(), options)
  end
end
