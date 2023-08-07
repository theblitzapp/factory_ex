defmodule FactoryEx.FactoryCache do
  @moduledoc """
  KV store that maps Ecto.Schema modules keys to Factory module values.

  # Getting Started

  To use this cache it must first be started. It can be added a child to your
  application supervisor or add the following snippet below to your test_helper.exs.

  ```elixir
  # test_helper.exs
  Cache.start_link([FactoryEx.FactoryCache])
  ```

  Once the cache add the following setup before your tests:

  ```elixir
  setup do
    Cache.SandboxRegistry.register_caches(FactoryEx.FactoryCache)
    FactoryEx.FactoryCache.setup()
  end
  ```

  ## Requirements

  The following steps are required to detect your factories:

  - Your application must have `factory_ex` as a dependency in `mix.exs`.
  - Your application defines a factory module for each schema used as a relational key
  - Your module contains the prefix `Factory`, ie. YourApp.Support.Factory.Schemas.Schema.
  - Your factory module defines the factory_ex `schema/0` callback function.

  Note: In umbrella applications the requirements are per application.

  ## Factory Module Prefix

  If your application's factory modules do not use the prefix `Factory` or you want to change
  which factory modules are loaded during tests you can configure the module prefix option at
  *compile* time with the following config:

  ```elixir
  config :factory_ex, :factory_module_prefix, Factory
  ```
  """
  use Cache,
    adapter: Cache.ETS,
    name: :factory_ex_factory_cache,
    sandbox?: true,
    opts: []

  @app :factory_ex
  @factory_prefix Application.compile_env(@app, :factory_module_prefix, Factory)
  @store :store

  @doc """
  Returns the result of the `build/1` function of the Factory associated with the given schema.
  """
  @spec build_params(module, map) :: map
  def build_params(ecto_schema, params \\ %{}) do
    fetch_schema_factory!(ecto_schema).build(params)
  end

  @doc "Creates the key-value store."
  @spec setup :: :ok
  def setup do
    [@app | FactoryEx.Utils.apps_that_depend_on(@app)]
    |> Enum.reduce(%{}, &lookup_factory_modules/2)
    |> put_store()
  end

  defp put_store(val) do
    put(@store, val)
  end

  defp get_store do
    with {:ok, nil} <- get(@store) do
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
    end
  end

  defp fetch_store! do
    {:ok, store} = get_store()
    store
  end

  defp lookup_factory_modules(app, acc) do
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

  defp fetch_schema_factory!(ecto_schema) do
    case Enum.find(fetch_store!(), fn {k, _} -> k === ecto_schema end) do
      nil ->
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

      {_, factory} -> factory
    end
  end
end
