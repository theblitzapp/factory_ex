defmodule FactoryEx.DataCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      alias FactoryEx.Support.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import FactoryEx.DataCase
    end
  end

  setup tags do
    setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(FactoryEx.Support.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(FactoryEx.Support.Repo, {:shared, self()})
    end
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        key_string_to_atom = String.to_existing_atom(key)

        opts
        |> Keyword.get(key_string_to_atom, key)
        |> to_string()
      end)
    end)
  end
end
