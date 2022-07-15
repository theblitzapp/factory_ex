defmodule FactoryEx.Utils do
  @moduledoc false

  @struct_fields [:__meta__]
  @whitelisted_modules [NaiveDateTime, DateTime, Date, Time]

  @doc """
  Changes structs into maps all the way down, excluding
  things like DateTime.
  """
  @spec deep_struct_to_map(any) :: any
  def deep_struct_to_map(%module{} = struct) when module in @whitelisted_modules do
    struct
  end

  def deep_struct_to_map(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Map.drop(@struct_fields)
    |> deep_struct_to_map()
  end

  def deep_struct_to_map(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, deep_struct_to_map(v)} end)
  end

  def deep_struct_to_map(list) when is_list(list) do
    Enum.map(list, &deep_struct_to_map/1)
  end

  def deep_struct_to_map(elem) do
    elem
  end

  def underscore_schema(ecto_schema) when is_atom(ecto_schema) do
    ecto_schema |> inspect |> underscore_schema
  end

  def underscore_schema(ecto_schema) do
    ecto_schema |> String.replace(".", "") |> Macro.underscore
  end

  def context_schema_name(ecto_schema) do
    ecto_schema
      |> String.split(".")
      |> Enum.take(-2)
      |> Enum.map_join("_", &String.downcase/1)
  end
end
