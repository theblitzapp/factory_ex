defmodule FactoryEx.FactoryCache do
  @moduledoc """
  This module implements a key-value store that maps Ecto.Schema modules
  to Factory module values. This is used to automatically generate
  relational ecto data structures through the `relational` option.

  # Getting Started

  To use this cache you must first start it with `Cache.start_link/1`.
  This can be added to your test_helper.exs file, for example:

  ```elixir
  # test_helper.exs
  Cache.start_link([FactoryEx.FactoryCache])
  ```

  Once the cache is started you must call `FactoryEx.FactoryCache.setup/0`
  before using the relational option in your tests.

  Once the cache add the following setup before your tests:

  ```elixir
  setup_all do
    FactoryEx.FactoryCache.setup()
  end
  ```

  In umbrella apps you can also start the cache once by checking
  if the cache has already started in your `test_helper.exs` file:

  ```elixir
  # test_helper.exs
  if !FactoryEx.FactoryCache.already_started?() do
    Cache.start_link([FactoryEx.FactoryCache])
    FactoryEx.FactoryCache.setup()
  end
  ```

  ## Requirements

  The following steps are required to detect your factories:

  - Your application must have `factory_ex` as a dependency in `mix.exs`.
  - Your application defines a factory module for each schema used as a relational key
  - Your module contains the prefix `Factory`, ie. YourApp.Support.Factory.Schemas.Schema.
  - Your factory module defines the factory_ex `schema/0` callback function.

  In umbrella applications these requirements are per application.

  ## Factory Module Prefix

  If your application's factory modules do not use the prefix `Factory` or you want to change
  which factory modules are loaded during tests you can configure the module prefix option at
  compile time with the following config:

  ```elixir
  config :factory_ex, :factory_module_prefix, Factory
  ```
  """
  use Cache,
    adapter: Cache.ETS,
    name: :factory_ex_factory_cache,
    sandbox?: false,
    opts: []

  @app :factory_ex
  @factory_prefix Application.compile_env(@app, :factory_module_prefix, Factory)
  @store :store

  @doc """
  Returns true if the cache is already started
  """
  @spec already_started?() :: true | false
  def already_started?, do: cache_name() |> :ets.whereis() |> is_reference()

  @doc """
  Returns the result of the `build/1` function of the Factory associated with the given schema.
  """
  @spec build_params(module, map) :: map
  def build_params(ecto_schema, params \\ %{}), do: fetch_factory!(ecto_schema).build(params)

  @doc """
  Creates the key-value store that maps Ecto.Schema modules to
  their factory modules.

  This function aggregates all factory modules from every app that
  depends on `factory_ex` and adds them to the store if they define
  the `schema/0` callback function.
  """
  @spec setup :: :ok
  def setup do
    [@app | FactoryEx.Utils.apps_that_depend_on(@app)]
    |> Enum.reduce(%{}, &aggregate_factory_modules/2)
    |> put_store()
  end

  defp aggregate_factory_modules(app, acc) do
    app
    |> FactoryEx.Utils.find_app_modules(@factory_prefix)
    |> Enum.reduce(acc, &maybe_put_factory_module/2)
  end

  defp maybe_put_factory_module(module, acc) do
    if FactoryEx.Utils.ensure_function_exported?(module, :schema, 0) do
      Map.put(acc, module.schema(), module)
    else
      acc
    end
  end

  defp fetch_factory!(ecto_schema) do
    with nil <- Map.get(fetch_store!(), ecto_schema) do
      raise """
      Factory not found for schema '#{inspect(ecto_schema)}'.

      This means the factory module does not exist or it was not loaded.

      To fix this error:

      - Add `factory_ex` as a depedency in `mix.exs` of the application that contains
        the schema '#{inspect(ecto_schema)}'. In umbrella applications you must add
        `factory_ex` as a dependency to each application that contain factory modules.

      - Create a factory for the schema '#{inspect(ecto_schema)}'

      - Add the prefix '#{inspect(@factory_prefix)}' to the factory module name. For example:
        YourApp.#{inspect(@factory_prefix)}.Module.
      """
    end
  end

  defp put_store(state), do: put(@store, state)

  defp fetch_store! do
    case get(@store) do
      {:ok, nil} ->
        raise """
        Factories not found!

        Add the following to your setup:

        ```
        setup do
          FactoryEx.FactoryCache.setup()
        end
        ```

        If setup/0 is already called ensure your application meets the requirements.
        See the module documentation for FactoryEx.FactoryCache for more information
        or `h FactoryEx.FactoryCache` in iex.

        """

      {:ok, state} ->
        state
    end
  end
end
