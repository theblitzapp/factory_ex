defmodule FactoryEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :factory_ex,
      version: "0.1.0",
      elixir: "~> 1.13",
      description: "Factories for elixir to help create data models at random, this works for any type of ecto structs",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
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
        "General": [
          FactoryEx
        ],

        "Adapters": [
          FactoryEx.Adapter
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
