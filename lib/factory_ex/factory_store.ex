defmodule FactoryEx.FactoryStore do
  @moduledoc """
  A simple key-value store that maps Ecto.Schema modules to Factory modules.

  ## Requirements

  - Your application defines a factory module for each schema used as a relational key
  - Your application has `factory_ex` as a depedency in `mix.exs`.
  - Your module contains the prefix `Factory`, ie. YourApp.Support.Factory.Schemas.Schema.
  - Your factory module defines the factory_ex `schema/0` callback function.

  Factory modules are stored in an ets table with their schema values as the key.
  This allows us to invoke the the appropriate factory module for a given schema.

  Let's look at an example:

  Call `FactoryEx.FactoryStore.all/0` to see all discovered factory modules.
  By default the modules defined by `factory_ex` will be displayed.

  ```elixir
  FactoryEx.FactoryStore.all
  [
    {FactoryEx.Support.Schema.Accounts.User, FactoryEx.Support.Factory.Accounts.User},
    {FactoryEx.Support.Schema.Accounts.TeamOrganization, FactoryEx.Support.Factory.Accounts.TeamOrganization},
    {FactoryEx.Support.Schema.Accounts.Label, FactoryEx.Support.Factory.Accounts.Label},
    {FactoryEx.Support.Schema.Accounts.Role, FactoryEx.Support.Factory.Accounts.Role},
    {FactoryEx.Support.Schema.Accounts.Team, FactoryEx.Support.Factory.Accounts.Team}
  ]
  ```

  To build the params for the schema `FactoryEx.Support.Schema.Accounts.User` we call
  `FactoryEx.FactoryStore.build_params/2` with the schema module. Arguments are
  passed to the factory module's `build/1` callback functions.

  ## Usage Examples

      FactoryEx.FactoryStore.build_params(FactoryEx.Support.Schema.Accounts.User)
      %{
        birthday: ~D[1992-10-04],
        email: "tyrese_welch@beier.org",
        gender: "male",
        location: "someplace",
        name: "Elisa Abbott"
      }

  ## Factory Module Prefix

  If your application's factory modules do not use the prefix `Factory` or you want to change
  which factory modules are loaded during tests you can configure the module prefix option at
  compile time with the following config:

  ```elixir
  config :factory_ex, :factory_module_prefix, Factory
  ```
  """
  use Task

  @tab :factory_ex_factory_store
  @tab_options [
    :set,
    :named_table,
    :public,
    read_concurrency: true,
    write_concurrency: true
  ]

  @app :factory_ex
  @factory_prefix Application.compile_env(@app, :factory_module_prefix, Factory)

  @doc false
  @spec start_link(any) :: {:ok, pid}
  def start_link(_) do
    Task.start_link(fn ->
      :ets.new(@tab, @tab_options)
      init()

      Process.hibernate(Function, :identity, [])
    end)
  end

  defp init do
    [@app | FactoryEx.Application.apps_that_depend_on(@app)]
    |> Enum.reduce(%{}, &lookup_factory_modules/2)
    |> Enum.map(&:ets.insert(@tab, &1))
  end

  defp lookup_factory_modules(app, acc) do
    app
    |> FactoryEx.Application.find_app_modules(@factory_prefix)
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
    case @tab |> :ets.lookup(ecto_schema) |> Keyword.get(ecto_schema) do
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

      factory -> factory
    end
  end

  @doc """
  Returns all factories in the ets table
  """
  @spec all() :: list({module, module}) | []
  def all, do: :ets.tab2list(@tab)

  @doc """
  Returns the result of the `build/1` function of the Factory associated with the given schema.
  """
  @spec build_params(module, map) :: map
  def build_params(ecto_schema, params \\ %{}) do
    fetch_schema_factory!(ecto_schema).build(params)
  end
end
