defmodule FactoryEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :factory_ex,
      version: "0.3.4",
      elixir: "~> 1.13",
      description: "Factories for elixir to help create data models at random, this works for any type of ecto structs",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix, :credo, :ecto_sql],
        plt_local_path: "dialyzer",
        plt_core_path: "dialyzer",
        list_unused_filters: true,
        flags: [:unmatched_returns]
      ],
      preferred_cli_env: [
        dialyzer: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0", optional: true},
      {:postgrex, "~> 0.16", optional: true},
      {:nimble_options, "~> 0.4 or ~> 1.0"},
      {:elixir_cache, "~> 0.3"},
      {:faker, ">= 0.0.0", only: [:dev, :test]},

      {:credo, "~> 1.6", only: [:dev, :test], runtime: false, optional: true},
      {:blitz_credo_checks, "~> 0.1", only: [:dev, :test], runtime: false, optional: true},
      {:excoveralls, "~> 0.10", only: :test, runtime: false, optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false, optional: true},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false, optional: true}
    ]
  end

  defp package do
    [
      maintainers: ["Mika Kalathil"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/theblitzapp/factory_ex"},
      files: ~w(mix.exs README.md CHANGELOG.md LICENSE lib config)
    ]
  end

  defp docs do
    [
      main: "FactoryEx",
      source_url: "https://github.com/theblitzapp/factory_ex",
      groups_for_modules: [
        General: [
          FactoryEx,
          FactoryEx.SchemaCounter,
          FactoryEx.AssociationBuilder,
          FactoryEx.FactoryCache
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
