ExUnit.start()
Faker.start()

{:ok, _} = :application.ensure_all_started([:postgrex])
{:ok, _} = FactoryEx.Support.Repo.start_link()

Cache.start_link([FactoryEx.FactoryCache])
FactoryEx.FactoryCache.setup()
