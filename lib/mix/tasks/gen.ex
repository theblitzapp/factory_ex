defmodule Mix.Tasks.FactoryEx.Gen do
  @moduledoc """
  This can be used to generate factories for usage with ecto `--repo` is required

  ### Example
  ```bash
  $ mix factory_ex.gen --repo MyApp.Repo MyApp.Accounts.User
  $ mix factory_ex.gen --repo MyApp.Repo MyApp.Accounts.User MyApp.Accounts.Role
  ```

  ### Options
  - `dirname` - Set directory name to generate into `../my_app/test/support/factory/`
  - `force` - Force create files, no confirmations
  - `quiet` - No output messages
  """

  use Mix.Task

  alias Mix.FactoryExHelpers

  @blacklist_fields [:updated_at, :inserted_at]

  @faker_mod_blacklist [
    Faker.Name
  ]

  @faker_functions (case :application.get_key(:faker, :modules) do
    {:ok, modules} ->
      modules
        |> Enum.filter(fn module ->
          module_level = module
            |> inspect
            |> String.codepoints
            |> Enum.filter(&(&1 === "."))
            |> length

          module_level === 1
        end)
        |> Enum.map(fn module ->
          functions = module.__info__(:functions)
            |> Enum.filter(fn {_name, arity} -> arity === 0 end)
            |> Enum.map(fn {name, _arity} -> name end)

          {module, functions}
        end)
        |> Enum.filter(fn {_module, functions} -> length(functions) > 0 end)

    e ->
      throw "Some weird error happened when trying to find faker functions\n#{inspect e, pretty: true}"
  end)

  def run(args) do
    FactoryExHelpers.ensure_not_in_umbrella!("factory_ex.gen.factory")

    {opts, extra_args, _} = OptionParser.parse(args,
      switches: [
        dirname: :string,
        app_name: :string,
        force: :boolean,
        quiet: :boolean,
        repo: :string
      ]
    )

    if opts[:app_name] && opts[:dirname] do
      raise to_string(IO.ANSI.format([
        :red, "Only one of ", :bright, "app_name", :reset,
        :red, " or ", :bright, "dirname", :reset,
        :red, " should be supplied"
      ]))
    end

    if validate_repo?(opts[:repo]) do
      ecto_schemas = Enum.map(extra_args, &FactoryExHelpers.string_to_module/1)

      ensure_schema_counter_start_added(opts)

      Enum.each(ecto_schemas, &generate_factory(&1, opts[:repo], opts))
    end
  end

  defp validate_repo?(repo) do
    if repo do
      FactoryExHelpers.string_to_module(repo)

      true
    else
      Mix.shell().error(to_string(IO.ANSI.format([
        :reset, :red, "Must provide ", :bright, "--repo", :reset,
        :red, " when using factory_ex.gen", :reset
      ])))

      false
    end
  end

  def ensure_schema_counter_start_added(opts) do
    directory = cond do
      opts[:dirname] -> opts[:dirname]
      opts[:app_name] -> Path.expand(Path.join(["../", opts[:app_name]]))
      true -> "."
    end

    "#{directory}/**/test_helper.exs"
      |> Path.wildcard
      |> Enum.each(fn path ->
        path = Path.expand(path)

        contents = File.read!(path)

        if not String.contains?(contents, "FactoryEx.SchemaCounter.start()") do
          path = Path.relative_to_cwd(path)
          Mix.shell().info([:green, "* injecting FactoryEx.SchemaCounter.start() into ", :reset, path])

          File.write!(path, contents <> "\nFactoryEx.SchemaCounter.start()", opts)
        end
      end)
  end

  def generate_factory(ecto_schema, repo, opts) do
    schema_fields = ecto_schema
      |> FactoryExHelpers.schema_fields()
      |> Kernel.--(FactoryExHelpers.schema_primary_key(ecto_schema) ++ @blacklist_fields)
      |> FactoryExHelpers.with_field_types(ecto_schema)
      |> Enum.reject(fn {_, type} -> type === :id end)

    Mix.Generator.create_file(
      schema_factory_path(ecto_schema, opts),
      factory_template(ecto_schema, repo, schema_fields, opts)
    )
  end

  defp schema_factory_path(ecto_schema, opts) do
    dirname = cond do
      opts[:dirname] -> opts[:dirname]
      opts[:app_name] -> Path.expand(Path.join(["../", opts[:app_name], "test/support/factory"]))
      true -> Path.expand("./test/support/factory/")
    end

    [context, schema] = ecto_schema |> inspect |> String.split(".") |> Enum.take(-2)
    dirname = Path.join(dirname, Macro.underscore(context))

    file_name = "#{Macro.underscore(schema)}.ex"

    if not File.dir?(dirname) do
      File.mkdir_p!(dirname)
    end

    dirname
      |> Path.join(file_name)
      |> Path.relative_to_cwd
  end

  defp factory_template(ecto_schema, repo, schema_fields, _opts) do
    Code.format_string!("""
    defmodule #{ecto_schema_factory_module(ecto_schema)} do
      @behaviour FactoryEx

      @impl FactoryEx
      def schema, do: #{inspect(ecto_schema)}

      @impl FactoryEx
      def repo, do: #{repo}

      @impl FactoryEx
      def build(args \\\\ %{}) do
        Map.merge(%{
          #{Enum.map_join(schema_fields, ",\n", &template_schema_field(&1, ecto_schema))}
        }, args)
      end
    end
    """)
  end

  defp ecto_schema_factory_module(ecto_schema) do
    [root_module | nested_modules] = ecto_schema |> inspect |> String.split(".")
    other_modules = nested_modules
      |> Enum.join(".")
      |> String.replace(~r/^Support\./, "") # This is just to support tests

    "#{root_module}.Support.Factory.#{other_modules}"
  end

  defp template_schema_field({field, type}, ecto_schema) do
    "#{field}: #{build_random_field(type, field, ecto_schema)}"
  end

  defp build_random_field(:integer, field, ecto_schema) do
    schema_name = ecto_schema
      |> inspect()
      |> String.split(".")
      |> Enum.map_join("_", &Macro.underscore/1)

    "FactoryEx.SchemaCounter.next(\"#{schema_name}_#{field}\")"
  end

  defp build_random_field(:string, field, ecto_schema) do
    ecto_schema = inspect(ecto_schema)
    field_name = "#{FactoryEx.Utils.context_schema_name(ecto_schema)}_#{field}"

    case find_faker_function_with_type(field, :string) do
      {module, function} ->
        "\"\#{#{inspect(module)}.#{function}()\}_\#{FactoryEx.SchemaCounter.next(\"#{field_name}\")\}\""
      nil -> "to_string(FactoryEx.SchemaCounter.next(\"#{field_name}\"))"
    end
  end

  defp build_random_field(:naive_datetime_usec, _field, _ecto_schema) do
    "10..30 |> Enum.random() |> Faker.DateTime.backward |> DateTime.to_naive"
  end

  defp build_random_field(:naive_datetime, _field, _ecto_schema) do
    "10..30 |> Enum.random() |> Faker.DateTime.backward |> DateTime.truncate(:second) |> DateTime.to_naive"
  end

  defp build_random_field(:utc_datetime_usec, _field, _ecto_schema) do
    "Faker.DateTime.backward(Enum.random(10..30))"
  end

  defp build_random_field(:utc_datetime, _field, _ecto_schema) do
    "Enum.random(10..30) |> Faker.DateTime.backward |> NaiveDateTime.truncate(:second)"
  end

  defp build_random_field(:date, _field, _ecto_schema) do
    "Faker.Date.backward(Enum.random(100..400))"
  end

  defp build_random_field({:parameterized, Ecto.Enum, %{mappings: mappings}}, _field, _ecto_schema) do
    enum_list = mappings |> Keyword.keys |> Enum.map_join(", ", &(":#{&1}"))

    "Enum.random([#{enum_list}])"
  end

  defp find_faker_function_with_type(field, type) do
    field
      |> matching_faker_functions
      |> Enum.find(fn {module, function} ->
        if module not in @faker_mod_blacklist do
          faker_fn_return_type = module
            |> apply(function, [])
            |> resolve_type

          faker_fn_return_type === type
        end
      end)
  end

  defp resolve_type(%NaiveDateTime{})  do
    :naive_datetime_usec
  end

  defp resolve_type(%DateTime{})  do
    :datetime_usec
  end

  defp resolve_type(%Date{})  do
    :date
  end

  defp resolve_type(%Time{})  do
    :time
  end

  defp resolve_type([]) do
    :array
  end

  defp resolve_type(list) when is_list(list) do
    {:array, resolve_type(hd(list))}
  end

  defp resolve_type(int) when is_integer(int) do
    :integer
  end

  defp resolve_type(float) when is_float(float) do
    :float
  end

  defp resolve_type(binary) when is_binary(binary) do
    :string
  end

  defp resolve_type({_, _, _} = _decimal) do
    :unsupported
  end

  def matching_faker_functions(field) do
    @faker_functions
      |> Enum.flat_map(fn {module, functions} ->
        Enum.map(functions, fn function_name ->
          module_name = module |> inspect |> String.replace("Faker", "")
          score = String.jaro_distance(to_string(function_name), to_string(field)) +
                  (String.jaro_distance(to_string(module_name), to_string(field)) / 2)

          {module, function_name, score}
        end)
      end)
      |> Enum.sort_by(fn {_mod, _fn_name, score} -> score end, :desc)
      |> Enum.map(fn {module, fn_name, _distance} -> {module, fn_name} end)
  end
end
