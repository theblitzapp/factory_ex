defmodule FactoryEx.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_, _) do
    FactoryEx.SchemaCounter.start()

    children = [
      FactoryEx.FactoryStore
    ]

    opts = [strategy: :one_for_one, name: FactoryEx.Supervisor]
    Supervisor.start_link(children, opts)
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
end
