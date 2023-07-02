defmodule FactoryEx.AssociationBuilder do
  @moduledoc """

  This module implements the api for auto generating Ecto Associations with factories.

  ## Requirements

  This module expects the `FactoryEx.FactoryCache` to have been started and initialized.
  See the module documentation for more information.

  ## How to Use

  The `relational` option is used to auto-generate parameters based on the keys. Each relational field
  must be a valid association.

  For example let's say you had a schema `Team` that had many `User` associations you can call build
  params with the `Team` factory and pass in the `users` association field as a relational argument.

  ```elixir
  FactoryEx.AssociationBuilder.build_params(
    FactoryEx.Support.Factory.Accounts.Team,
    %{},
    relational: [:users]
  )
  ```

  We don't specify `team` in the relational keys since the team is the root level schema and the
  association builder expects all fields at the top level to be valid associations of the `Team` schema.

  Because the association builder traverses your Ecto.Schema's associations based on the fields if
  the field specified does not exist as a valid association on the schema an error is raised.

  ## Examples

  ```elixir
  #
  # Create params for a one-to-one relationship
  #
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

  #
  # Create a specific count params for a one-to-many relationship
  #
  FactoryEx.AssociationBuilder.build_params(
    FactoryEx.Support.Factory.Accounts.TeamOrganization,
    %{teams: [%{}, %{name: "awesome team name"}]},
    relational: [:teams]
  )
  %{teams: [%{name: "Lindgren-Zemlak"}, %{name: "awesome team name"}]}

  #
  # You can also build deep relational structures
  #
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
    |> case do
      nil -> params
      assoc_params -> Map.put(params, field, assoc_params)
    end
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
