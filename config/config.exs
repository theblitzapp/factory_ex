import Config

config :factory_ex, ecto_repos: [FactoryEx.Support.Repo]
config :factory_ex, :sql_sandbox, true
config :factory_ex, FactoryEx.Support.Repo,
  username: "postgres",
  password: "postgres",
  database: "factory_ex_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5
