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

  Once the cache is started the store then needs to be created.

  ```elixir
  FactoryEx.FactoryCache.setup()
  :ok
  ```

  This function finds your factory modules, maps them to their schemas and stores
  the result. This also works with umbrella apps out of the box.

  We can now view the modules in the store with `FactoryEx.FactoryCache.get_store/0`.
  By default the schemas in factory_ex are shown. Here's an example:

  ```elixir
  FactoryEx.FactoryCache.fetch_store!()
  %{
    FactoryEx.Support.Schema.Accounts.Label => FactoryEx.Support.Factory.Accounts.Label,
    FactoryEx.Support.Schema.Accounts.Role => FactoryEx.Support.Factory.Accounts.Role,
    FactoryEx.Support.Schema.Accounts.Team => FactoryEx.Support.Factory.Accounts.Team,
    FactoryEx.Support.Schema.Accounts.TeamOrganization => FactoryEx.Support.Factory.Accounts.TeamOrganization,
    FactoryEx.Support.Schema.Accounts.User => FactoryEx.Support.Factory.Accounts.User
  }
  ```

  Once the store is created you can build parameters for a given schema with `FactoryEx.FactoryCache.build_params/2`.
  Let's go through an example using a schema in the store:

  ```elixir
  FactoryEx.FactoryCache.build_params(FactoryEx.Support.Schema.Accounts.User, %{location: "custom_location"})
  %{
    birthday: ~D[1992-10-04],
    email: "tyrese_welch@beier.org",
    gender: "male",
    location: "custom_location",
    name: "Elisa Abbott"
  }
  ```

  In the example above we called `FactoryEx.FactoryCache.build_params/2` with the schema
  `FactoryEx.Support.Factory.Accounts.User` and some parameters. In the store the schema
  key has the value of `FactoryEx.Support.Factory.Accounts.User`. This in turn calls
  the factory's callback function `build/1` called with the parameters.

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
    name: :factory_ex_factory_store,
    sandbox?: false,
    opts: []

  @app :factory_ex
  @factory_prefix Application.compile_env(@app, :factory_module_prefix, Factory)
  @store :store

  @doc "Returns the store map. Raises if no values exist."
  @spec fetch_store!() :: map()
  def fetch_store! do
    {:ok, store} = get_store()
    store
  end

  @doc "Puts the result of `build_store/0` in the store."
  @spec setup :: :ok
  def setup do
    [@app | FactoryEx.Utils.apps_that_depend_on(@app)]
    |> Enum.reduce(%{}, &lookup_factory_modules/2)
    |> put_store()
  end

  defp put_store(val) do
    with :ok <- ensure_cache_started!() do
      put(@store, val)
    end
  end

  defp get_store do
    with :ok <- ensure_cache_started!(),
      {:ok, nil} <- get(@store) do
        raise "FactoryCache store not found! To fix this error call `FactoryEx.FactoryCache.setup/0`."
    end
  end

  defp ensure_cache_started! do
    if cache_started?() do
      :ok
    else
      raise """
      FactoryEx.FactoryCache not started!

      Add the following to your test_helper.exs:

      ```
      # test_helper.exs
      Cache.start_link([FactoryEx.FactoryCache])
      ```
      """
    end
  end

  defp cache_started? do
    case :ets.whereis(FactoryEx.FactoryCache.cache_name()) do
      :undefined -> false
      _ -> true
    end
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

  @doc """
  Returns the result of the `build/1` function of the Factory associated with the given schema.
  """
  @spec build_params(module, map) :: map
  def build_params(ecto_schema, params \\ %{}) do
    fetch_schema_factory!(ecto_schema).build(params)
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
