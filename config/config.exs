import Config

config :factory_ex, ecto_repos: [FactoryEx.Support.Repo]
config :factory_ex, :sql_sandbox, true
config :factory_ex, FactoryEx.Support.Repo,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  database: "factory_ex_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: String.to_integer(System.get_env("POSTGRES_POOL_SIZE", "10"))
