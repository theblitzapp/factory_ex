ExUnit.start()

Application.put_env(:factory_ex, :ecto_repos, [FactoryEx.Support.Repo])

Application.put_env(:factory_ex, :sql_sandbox, true)

FactoryEx.Support.Repo.start_link([
  username: "postgres",
  password: "postgres",
  database: "factory_ex_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
])

Cache.start_link([FactoryEx.FactoryCache])
FactoryEx.FactoryCache.setup()
