defmodule FactoryEx.Utils do
  @moduledoc false

  @struct_fields [:__meta__]
  @whitelisted_modules [NaiveDateTime, DateTime, Date, Time]
  @camelize_regex ~r/(?:^|[-_])|(?=[A-Z][a-z])/

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
    ecto_schema |> String.replace(".", "") |> Macro.underscore()
  end

  def context_schema_name(ecto_schema) do
    ecto_schema
    |> String.split(".")
    |> Enum.take(-2)
    |> Enum.map_join("_", &Macro.underscore/1)
  end

  @doc """
  Converts all string keys to string

  ### Example

      iex> FactoryEx.Utils.stringify_keys(%{"test" => 5, hello: 4})
      %{"test" => 5, "hello" => 4}

      iex> FactoryEx.Utils.stringify_keys([%{"a" => 5}, %{b: 2}])
      [%{"a" => 5}, %{"b" => 2}]
  """
  @spec stringify_keys(Enum.t()) :: Enum.t()
  def stringify_keys(map) do
    transform_keys(map, fn
      key when is_binary(key) -> key
      key when is_atom(key) -> Atom.to_string(key)
    end)
  end

  @spec camelize_keys(Enum.t()) :: Enum.t()
  def camelize_keys(map) do
    transform_keys(map, fn
      key when is_binary(key) -> camelize(key, :lower)
      key when is_atom(key) -> camelize(to_string(key), :lower)
    end)
  end

  defp transform_keys(map, transform_fn) when is_map(map) do
    Enum.into(map, %{}, fn {key, value} ->
      {transform_fn.(key), transform_keys(value, transform_fn)}
    end)
  end

  defp transform_keys(list, transform_fn) when is_list(list) do
    Enum.map(list, &transform_keys(&1, transform_fn))
  end

  defp transform_keys(item, _transform_fn), do: item

  def camelize(word, option \\ :upper) do
    case Regex.split(@camelize_regex, to_string(word)) do
      words ->
        words
        |> Enum.filter(&(&1 != ""))
        |> camelize_list(option)
        |> Enum.join()
    end
  end

  defp camelize_list([], _), do: []

  defp camelize_list([h | tail], :lower) do
    [String.downcase(h)] ++ camelize_list(tail, :upper)
  end

  defp camelize_list([h | tail], :upper) do
    [String.capitalize(h)] ++ camelize_list(tail, :upper)
  end

  @doc """
  Returns `true` if the second list exists in the first list or `false`.

  ## Example
      iex> FactoryEx.Util.List.sublist?([:a, :b, :c], [:b, :c])
      true
  """
  def sublist?([], _), do: false

  def sublist?([_ | t] = l1, l2) do
    List.starts_with?(l1, l2) or sublist?(t, l2)
  end

  @doc """
  Ensure the module with the public function and arity is defined

  Note: `function_exported/3` does not load the module in case it is not loaded.
  If the BEAM is running in `interactive` mode there is a chance this module has not
  been loaded yet. `Code.ensure_loaded/1` is used to ensure the module is loaded
  first.

  Docs: https://hexdocs.pm/elixir/1.12/Kernel.html#function_exported?/3
  """
  def ensure_function_exported?(module, fun, arity) do
    case Code.ensure_loaded(module) do
      {:module, module} ->
        function_exported?(module, fun, arity)

      {:error, reason} ->
        raise """
          Code failed to load module `#{inspect(module)}` with reason: #{inspect(reason)}!
          Ensure the module name is correct and it exists.
          """
    end
  end

  def apps_that_depend_on(dep) do
    :application.loaded_applications()
    |> Enum.reduce([], fn {app, _, _}, acc ->
      deps = Application.spec(app)[:applications]
      (dep in deps && acc ++ [app]) || acc
    end)
  end

  def find_app_modules(app, prefix) do
    case :application.get_key(app, :modules) do
      {:ok, modules} ->
        prefix = Module.split(prefix)
        Enum.filter(modules, &(&1 |> Module.split() |> FactoryEx.Utils.sublist?(prefix)))

      _ -> raise "modules not found for app #{inspect(app)}."
    end
  end

  @doc """
  Deep Converts `{count, attrs}` to list of `attrs`.

  ## Examples

      iex> FactoryEx.Utils.expand_count_tuples(%{hello: {2, %{world: {2, %{foo: :bar}}}}})
      %{
        hello: [
          %{world: [%{foo: :bar}, %{foo: :bar}]},
          %{world: [%{foo: :bar}, %{foo: :bar}]}
        ]
      }

      iex> FactoryEx.Utils.expand_count_tuples(%{hello: [%{foo: "bar"}, {2, %{}}]})
      %{hello: [%{foo: "bar"}, %{}, %{}]}

      iex> FactoryEx.Utils.expand_count_tuples(%{hello: [%{foo: {1, %{}}}, {1, %{qux: {1, %{bux: "hello world"}}}}]})
      %{hello: [%{foo: [%{}]}, %{qux: [%{bux: "hello world"}]}]}
  """
  @spec expand_count_tuples(map() | list()) :: map()
  def expand_count_tuples(enum) when is_map(enum) or is_list(enum), do: enum |> Enum.map(&transform/1) |> Map.new()

  def expand_count_tuples(val), do: val

  defp expand_many_count_tuples(count, attrs), do: Enum.map(1..count, fn _ -> expand_count_tuples(attrs) end)

  defp transform({key, attrs}) when is_map(attrs), do: {key, expand_count_tuples(attrs)}

  defp transform({key, many_attrs}) when is_list(many_attrs) do
    attrs =
      Enum.reduce(many_attrs, [], fn
        {count, attrs}, acc ->
          acc ++ expand_many_count_tuples(count, attrs)

        attrs, acc ->
          acc ++ [expand_count_tuples(attrs)]

      end)

    {key, attrs}
  end

  defp transform({key, {count, attrs}}) do
    {key, expand_many_count_tuples(count, attrs)}
  end

  defp transform(attrs) do
    attrs
  end
end
