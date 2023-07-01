defmodule FactoryEx.AssociationBuilder do
  @moduledoc """

  This module implements the api for auto generating Ecto Associations with factories.

  To use this api you must pass keys (which can be type of `:list` or `:keyword_list`) to the
  `relational` option. These keys are used by the `build_params/3` to find the appropriate
  Factory for an Ecto Schema and invoke the `build_params/3` callback function. This allows you
  to build any relational data structure declaratively.

  In the following section we will explain how `build_params/3` works with relational keys:

  - For each relational key, we try to fetch the the ecto schema's associations. If the field does
    not exist for the given schema an error is raised otherwise the association is used to create
    one or many params for the field based on the association's cardinality.

  - If the `owner_key` of the association's schema field is not set, the factory's `build/1`
    function will be invoked with the field's existing value. If the owner key is set the
    field is skipped and the existing value will be kept. Any existing parameters not passed
    as a relational key will be kept. If this behaviour is not desired you can set the
    `check_owner_field?` option to `false` and the parameters will be generated when the
    owner key is set.

  ## Examples

    # Create params for a one-to-one relationship
    FactoryEx.AssociationBuilder.build_params(
      FactoryEx.Support.Factory.Accounts.User,
      %{pre_existing_params: "hello world!"},
      relational: [:role, :team]
    )
    %{
      pre_existing_params: "hello world!",
      role: %{code: "Utah cats"},
      team: %{name: "Macejkovic Group"}
    }

    # Create params for a one-to-many relationship
    FactoryEx.AssociationBuilder.build_params(
      FactoryEx.Support.Factory.Accounts.TeamOrganization,
      %{teams: [%{}, %{}]},
      relational: [:teams]
    )
    %{teams: [%{name: "Lindgren-Zemlak"}, %{name: "Kutch Group"}]}

    # Create deep relational structure and override specific field values
    FactoryEx.AssociationBuilder.build_params(
      FactoryEx.Support.Factory.Accounts.TeamOrganization,
      %{teams: [%{name: "team name goes here", users: [%{name: "first user name"}, %{}]}]},
      relational: [teams: [users: [:labels, :role]]]
    )
    %{
      teams: [
        %{
          name: "team name goes here",
          users: [
            %{
              birthday: ~D[1992-10-04],
              email: "ivy_lind@braun.info",
              gender: "male",
              labels: [%{label: "expedita"}],
              location: "someplace",
              name: "first user name",
              role: %{code: "Iowa penguins"}
            },
            %{
              birthday: ~D[1992-10-04],
              email: "dillan1930@nolan.biz",
              gender: "male",
              labels: [%{label: "exercitationem"}],
              location: "someplace",
              name: "Name Zulauf Jr.",
              role: %{code: "New Hampshire dwarves"}
            }
          ]
        }
      ]
    }
  """

  @doc """
  Builds Ecto Association parameters.
  """
  @spec build_params(module(), map(), Keyword.t()) :: map()
  def build_params(factory_module, params \\ %{}, options \\ []) do
    schema = factory_module.schema()
    assoc_fields = Keyword.get(options, :relational, [])
    check_owner_key? = Keyword.get(options, :check_owner_key?, true)

    convert_fields_to_params(schema, params, assoc_fields, check_owner_key?)
  end

  defp convert_fields_to_params(schema, params, assoc_fields, check_owner_key?) do
    Enum.reduce(assoc_fields, params, &create_schema_params(schema, &1, &2, check_owner_key?))
  end

  defp create_schema_params(schema, {field, assoc_fields}, params, check_owner_key?) do
    schema
    |> fetch_assoc!(field)
    |> create_one_or_many_params(params, field, assoc_fields, check_owner_key?)
    |> case do
      nil -> params
      assoc_params -> Map.put(params, field, assoc_params)
    end
  end

  defp create_schema_params(schema, field, params, check_owner_key?) do
    create_schema_params(schema, {field, []}, params, check_owner_key?)
  end

  defp create_one_or_many_params(
      %{cardinality: :many, queryable: queryable} = assoc,
      params,
      field,
      assoc_fields,
      check_owner_key?
    ) do
    if check_owner_key? and owner_key_is_set?(assoc, params) do
      Map.get(params, field)
    else
      params
      |> Map.get(field, [%{}])
      |> Enum.map(&factory_build(queryable, &1, assoc_fields, check_owner_key?))
    end
  end

  defp create_one_or_many_params(
      %{cardinality: :one, queryable: queryable} = assoc,
      params,
      field,
      assoc_fields,
      check_owner_key?
    ) do
    if check_owner_key? and owner_key_is_set?(assoc, params) do
      Map.get(params, field)
    else
      params = Map.get(params, field, %{})
      factory_build(queryable, params, assoc_fields, check_owner_key?)
    end
  end

  defp owner_key_is_set?(assoc, params) do
    case Map.get(params, assoc.owner_key) do
      nil -> false
      _ -> true
    end
  end

  defp factory_build(queryable, params, assoc_fields, check_owner_key?) do
    parent = FactoryEx.FactoryCache.build_params(queryable, params)
    assoc = convert_fields_to_params(queryable, params, assoc_fields, check_owner_key?)

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
