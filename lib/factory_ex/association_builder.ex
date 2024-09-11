defmodule FactoryEx.AssociationBuilder do
  @moduledoc """

  This module implements the api for auto generating Ecto Associations with factories.

  ## Requirements

  This module expects the `FactoryEx.FactoryCache` to have been started and initialized.
  See the module documentation for more information.

  ## Relational Builder

  This is an introduction to the `relational` option which is used to auto-generate
  factory parameters based on the keys. Let's look at an example.

  If a `Team` has many `User` associations you can build many params using the `Team`
  factory and pass `users` as the field in the relational option.

  ```elixir
  FactoryEx.AssociationBuilder.build_params(
    FactoryEx.Support.Factory.Accounts.Team,
    %{},
    relational: [:users]
  )
  ```

  Note that we did not add the field `team` since the team is the parent schema and all fields
  must be valid associations of the team schema. The association builder may raise if a field
  is not a valid ecto association for the given factory's schema.

  ## Examples

  ```elixir
  # Create params for a one-to-one relationship
  FactoryEx.AssociationBuilder.build_params(
    FactoryEx.Support.Factory.Accounts.User,
    %{name: "Jane Doe"},
    relational: [:role, :team]
  )
  %{
    name: "Jane Doe",
    role: %{code: "Utah cats"},
    team: %{name: "Macejkovic Group"}
  }

  # Create a specific count params for a one-to-many relationship
  FactoryEx.AssociationBuilder.build_params(
    FactoryEx.Support.Factory.Accounts.TeamOrganization,
    %{teams: [%{}, %{name: "awesome team name"}]},
    relational: [:teams]
  )
  %{teams: [%{name: "Lindgren-Zemlak"}, %{name: "awesome team name"}]}

  # You can also build deep relational structures
  FactoryEx.AssociationBuilder.build_params(
    FactoryEx.Support.Factory.Accounts.TeamOrganization,
    %{},
    relational: [teams: [users: [:labels, :role]]]
  )
  %{
    teams: [
      %{
        name: "Leffler Group",
        users: [
          %{
            birthday: ~D[1992-10-04],
            email: "suzanne.yundt@armstrong.info",
            gender: "male",
            labels: [%{label: "autem"}],
            location: "someplace",
            name: "Gerda Waelchi",
            role: %{code: "North Carolina whales"}
          }
        ]
      }
    ]
  }
  ```
  """

  @doc """
  Builds Ecto Association parameters.
  """
  @spec build_params(module(), map(), Keyword.t()) :: map()
  def build_params(factory_module, params \\ %{}, options \\ []) do
    schema = factory_module.schema()
    assoc_fields = Keyword.get(options, :relational, [])

    convert_fields_to_params(schema, params, assoc_fields)
  end

  defp convert_fields_to_params(schema, params, assoc_fields) do
    Enum.reduce(assoc_fields, params, &create_schema_params(schema, &1, &2))
  end

  defp create_schema_params(schema, {field, assoc_fields}, params) do
    schema
    |> fetch_assoc!(field)
    |> create_one_or_many_params(params, field, assoc_fields)
    |> then(fn
      nil -> params
      assoc_params -> Map.put(params, field, assoc_params)
    end)
  end

  defp create_schema_params(schema, field, params) do
    create_schema_params(schema, {field, []}, params)
  end

  defp create_one_or_many_params(
    %{cardinality: :many, queryable: queryable},
    params,
    field,
    assoc_fields
  ) do
    params
    |> Map.get(field, [%{}])
    |> Enum.map(&factory_build(queryable, &1, assoc_fields))
  end

  defp create_one_or_many_params(
    %{cardinality: :one, queryable: queryable},
    params,
    field,
    assoc_fields
  ) do
    params = Map.get(params, field, %{})
    factory_build(queryable, params, assoc_fields)
  end

  defp factory_build(queryable, params, assoc_fields) do
    parent = FactoryEx.FactoryCache.build_params(queryable, params)
    assoc = convert_fields_to_params(queryable, params, assoc_fields)

    Map.merge(parent, assoc)
  end

  defp fetch_assoc!(schema, field) do
    assocs = schema.__schema__(:associations)

    if Enum.member?(assocs, field) do
      schema.__schema__(:association, field)
    else
      raise """
      The field '#{inspect(field)}' you entered was not found on schema '#{inspect(schema)}'.

      Did you mean one of the following fields?
      #{inspect(assocs)}

      To fix this error:

      - Ensure the field exists on the schema '#{inspect(schema)}'.

      - Return a schema from the `schema/0` callback function that contains the field '#{inspect(field)}'.
      """
    end
  end
end
