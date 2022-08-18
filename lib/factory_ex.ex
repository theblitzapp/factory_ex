defmodule FactoryEx do
  @build_definition [
    keys: [
      type: {:in, [:atom, :string, :camel_string]},
      doc: "Sets the type of keys to have in the built object, can be one of `:atom`, `:string` or `:camel_string`"
    ]
  ]

  @moduledoc """
  #{File.read!("./README.md")}

  ### FactoryEx.build options
  We can also specify options to `&FactoryEx.build/3`

  #{NimbleOptions.docs(@build_definition)}
  """

  alias FactoryEx.Utils

  @type build_opts :: [
    keys: :atom | :string | :camel_string
  ]

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
  Builds many parameters for a schema `changeset/2` function given the factory
  `module` and an optional list/map of `params`.
  """
  @spec build_many_params(pos_integer, module()) :: [map()]
  @spec build_many_params(pos_integer, module(), keyword() | map()) :: [map()]
  @spec build_many_params(pos_integer, module(), keyword() | map(), build_opts) :: [map()]
  def build_many_params(count, module, params \\ %{}, opts \\ []) do
    Enum.map(1..count, fn _ -> build_params(module, params, opts) end)
  end

  @doc """
  Builds the parameters for a schema `changeset/2` function given the factory
  `module` and an optional list/map of `params`.
  """
  @spec build_params(module()) :: map()
  @spec build_params(module(), keyword() | map()) :: map()
  @spec build_params(module(), keyword() | map(), build_opts) :: map()
  def build_params(module, params \\ %{}, opts \\ [])

  def build_params(module, params, opts) when is_list(params) do
    build_params(module, Map.new(params), opts)
  end

  def build_params(module, params, opts) do
    opts = NimbleOptions.validate!(opts, @build_definition)

    params
    |> module.build()
    |> Utils.deep_struct_to_map()
    |> maybe_encode_keys(opts)
  end

  defp maybe_encode_keys(params, []), do: params

  defp maybe_encode_keys(params, opts) do
    case opts[:keys] do
      nil -> params
      :atom -> params
      :string -> Utils.stringify_keys(params)
      :camel_string -> Utils.camelize_keys(params)
    end
  end

  @spec build_invalid_params(module()) :: map()
  def build_invalid_params(module) do
    params = build_params(module)
    schema = module.schema()

    field = schema.__schema__(:fields)
      |> Kernel.--([:updated_at, :inserted_at, :id])
      |> Enum.reject(&(schema.__schema__(:type, &1) === :id))
      |> Enum.random

    field_type = schema.__schema__(:type, field)

    field_value = case field_type do
      :integer -> "asdfd"
      :string -> 1239
      _ -> 4321
    end

    Map.put(params, field, field_value)
  end

  @doc """
  Builds a schema given the factory `module` and an optional
  list/map of `params`.
  """
  @spec build(module()) :: Ecto.Schema.t()
  @spec build(module(), keyword() | map()) :: Ecto.Schema.t()
  def build(module, params \\ %{}, options \\ [])

  def build(module, params, options) when is_list(params) do
    build(module, Map.new(params), options)
  end

  def build(module, params, options) do
    validate = Keyword.get(options, :validate, true)

    params
    |> module.build()
    |> maybe_changeset(module, validate)
    |> case do
      %Ecto.Changeset{} = changeset -> Ecto.Changeset.apply_action!(changeset, :insert)
      struct when is_struct(struct) -> struct
    end
  end

  @doc """
  Inserts a schema given the factory `module` and an optional list/map of
  `params`. Fails on error.
  """
  @spec insert!(module()) :: Ecto.Schema.t() | no_return()
  @spec insert!(module(), keyword() | map(), Keyword.t()) :: Ecto.Schema.t() | no_return()
  def insert!(module, params \\ %{}, options \\ [])

  def insert!(module, params, options) when is_list(params) do
    insert!(module, Map.new(params), options)
  end

  def insert!(module, params, options) do
    validate = Keyword.get(options, :validate, true)

    params
    |> module.build()
    |> maybe_changeset(module, validate)
    |> module.repo().insert!(options)
  end

  @doc """
  Insert as many as `count` schemas given the factory `module` and an optional
  list/map of `params`.
  """
  @spec insert_many!(pos_integer(), module()) :: [Ecto.Schema.t()]
  @spec insert_many!(pos_integer(), module(), keyword() | map()) :: [Ecto.Schema.t()]
  def insert_many!(count, module, params \\ %{}, options \\ []) when count > 0 do
    Enum.map(1..count, fn _ -> insert!(module, params, options) end)
  end

  @doc """
  Removes all the instances of a schema from the database given its factory
  `module`.
  """
  @spec cleanup(module) :: {integer(), nil | [term()]}
  def cleanup(module, options \\ []) do
    module.repo().delete_all(module.schema(), options)
  end

  defp maybe_changeset(params, module, validate) do
    if validate && schema?(module) do
      params = Utils.deep_struct_to_map(params)

      if create_changeset_defined?(module.schema()) do
        module.schema().create_changeset(params)
      else
        module.schema().changeset(struct(module.schema(), %{}), params)
      end
    else
      struct!(module.schema, params)
    end
  end

  defp create_changeset_defined?(module) do
    function_exported?(module, :create_changeset, 1)
  end

  defp schema?(module) do
    function_exported?(module.schema(), :__schema__, 1)
  end
end
