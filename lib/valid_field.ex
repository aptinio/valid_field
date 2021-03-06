defmodule ValidField do
  import ExUnit.Assertions, only: [assert: 2]
  @moduledoc ~S"""
  ValidField allows for unit testing values against a changeset.
  """

  @doc """
  Raises an ExUnit.AssertionError when the values for the field are invalid for
  the changset provided. Returns the original changset map from `with_changeset/1`
  to allow subsequent calls to be piped

  ## Examples
      iex> ValidField.with_changeset(%Model{})
      ...> |> ValidField.assert_valid_field(:first_name, ["Test"])
      ...> |> ValidField.assert_valid_field(:last_name, ["Value"])
      iex> ValidField.with_changeset(%Model{})
      ...> |> ValidField.assert_valid_field(:first_name, [nil, ""])
      ** (ExUnit.AssertionError) Expected the following values to be valid for "first_name": nil, ""
  """
  @spec assert_valid_field(map, atom, list) :: map
  def assert_valid_field(changeset, field, values) do
    invalid_values =
      changeset
      |> map_value_assertions(field, values)
      |> Enum.filter_map(fn {_key, value} -> value end, fn {key, _value} -> key end)

    assert invalid_values == [], "Expected the following values to be valid for #{inspect Atom.to_string(field)}: #{_format_values invalid_values}"

    changeset
  end

  @doc """
  Will assert if the given field's current value in the changeset is valid or not.

  ## Examples
      iex> ValidField.with_changeset(%Model{first_name: "Test"})
      ...> |> ValidField.assert_valid_field(:first_name)
      iex> ValidField.with_changeset(%Model{})
      ...> |> ValidField.assert_valid_field(:first_name)
      ** (ExUnit.AssertionError) Expected the following values to be valid for "first_name": nil
  """
  @spec assert_valid_field(map, atom) :: map
  def assert_valid_field(changeset, field) do
    assert_valid_field(changeset, field, [Map.get(changeset.model, field)])
  end

  @doc """
  Will assert if the given fields current values in the changeset are valid or not.

  Only returns an error on the first occurance, doesn't collect.

  ## Examples
      iex> ValidField.with_changeset(%Model{})
      ...> |> ValidField.assert_valid_fields([:first_name, :last_name])
      iex> ValidField.with_changeset(%Model{first_name: "Test", last_name: "Something"})
      ...> |> ValidField.assert_valid_fields([:first_name, :last_name])
      ** (ExUnit.AssertionError) Expected the following values to be valid for "first_name": nil
  """
  @spec assert_valid_fields(map, list) :: map
  def assert_valid_fields(changeset, fields) when is_list(fields) do
    Enum.each(fields, &(assert_valid_field(changeset, &1)))
  end

  @doc """
  Raises an ExUnit.AssertionError when the values for the field are valid for
  the changset provided. Returns the original changset map from `with_changeset/1`
  to allow subsequent calls to be piped

  ## Examples
      iex> ValidField.with_changeset(%Model{})
      ...> |> ValidField.assert_invalid_field(:first_name, [nil])
      ...> |> ValidField.assert_invalid_field(:first_name, [""])
      iex> ValidField.with_changeset(%Model{})
      ...> |> ValidField.assert_invalid_field(:first_name, ["Test"])
      ** (ExUnit.AssertionError) Expected the following values to be invalid for "first_name": "Test"
  """
  @spec assert_invalid_field(map, atom, list) :: map
  def assert_invalid_field(changeset, field, values) do
    valid_values =
      changeset
      |> map_value_assertions(field, values)
      |> Enum.filter_map(fn {_key, value} -> !value end, fn {key, _value} -> key end)

    assert valid_values == [], "Expected the following values to be invalid for #{inspect Atom.to_string(field)}: #{_format_values valid_values}"

    changeset
  end

  @doc """
  Will assert if the given field's current value in the changeset is invalid or not.

  ## Examples
      iex> ValidField.with_changeset(%Model{})
      ...> |> ValidField.assert_invalid_field(:first_name)
      iex> ValidField.with_changeset(%Model{first_name: "Test"})
      ...> |> ValidField.assert_invalid_field(:first_name)
      ** (ExUnit.AssertionError) Expected the following values to be invalid for "first_name": "Test"
  """
  @spec assert_invalid_field(map, atom) :: map
  def assert_invalid_field(changeset, field) do
    assert_invalid_field(changeset, field, [Map.get(changeset.model, field)])
  end

  @doc """
  Will assert if the given fields current values in the changeset are invalid or not.

  Only returns an error on the first occurance, doesn't collect.

  ## Examples
      iex> ValidField.with_changeset(%Model{})
      ...> |> ValidField.assert_invalid_fields([:first_name])
      iex> ValidField.with_changeset(%Model{first_name: "Test"})
      ...> |> ValidField.assert_invalid_fields([:first_name])
      ** (ExUnit.AssertionError) Expected the following values to be invalid for "first_name": "Test"
  """
  @spec assert_invalid_fields(map, list) :: map
  def assert_invalid_fields(changeset, fields) when is_list(fields) do
    Enum.each fields, fn(field) -> assert_invalid_field(changeset, field) end
  end

  @doc """
  Combines `assert_valid_field/3` and `assert_invalid_field/3` into a single call.
  The third argument is the collection of valid values to be tested. The fourth argument 
  is the collection of invalid values to be tested.

  ## Examples
      ValidField.with_changeset(%Model{})
      |> ValidField.assert_field(:first_name, ["George", "Barry"], ["", nil])
  """
  @spec assert_field(map, atom, list, list) :: map
  def assert_field(changeset, field, valid_values, invalid_values) do
    changeset
    |> assert_valid_field(field, valid_values)
    |> assert_invalid_field(field, invalid_values)
  end

  @doc """
  Returns a changeset map to be used with `assert_valid_field/3` or
  `assert_invalid_field/3`. When with_changeset is passed a single arguments, it is
  assumed to be an Ecto Model struct and will call the `changeset` function on
  the struct's module

  ## Examples
      ValidField.with_changeset(%Model{})
      |> ValidField.assert_invalid_field(:first_name, [nil])
      |> ValidField.assert_invalid_field(:first_name, [""])
  """
  @spec with_changeset(Ecto.Model.t) :: map
  def with_changeset(model),
    do: with_changeset(model, &model.__struct__.changeset/2)

  @doc """
  Returns a changeset map to be used with `assert_valid_field/3` or
  `assert_invalid_field/3`. The function passed to `with_changeset/2` must accept two
  arguments, the first being the model provided to `with_changeset/2`, the second
  being the map of properties to be applied in the changeset.

  ## Examples
      ValidField.with_changeset(%Model{}, &Model.changeset/2)
      |> ValidField.assert_invalid_field(:first_name, [nil])
      |> ValidField.assert_invalid_field(:first_name, [""])
  """
  @spec with_changeset(Ecto.Model.t, function) :: map
  def with_changeset(model, func) when is_function(func),
    do: %{model: model, changeset_func: func}

  @doc """
  Add values that will be set on the changeset during assertion runs
  """
  @spec put_params(map, map) :: map
  def put_params(changeset, params) when is_map(changeset) do
    Map.put(changeset, :params, params)
  end

  defp _format_values(values) do
    values
    |> Enum.map(&inspect/1)
    |> Enum.join(", ")
  end

  defp map_value_assertions(changeset, field, values) do
    values
    |> Enum.map(&({&1, invalid_for?(changeset, field, &1)}))
  end

  defp invalid_for?(%{model: model, params: params, changeset_func: changeset}, field, value) do
    params =
      params
      |> Map.put(field, value)
      |> stringify_keys()

    changeset.(model, params).errors
    |> Dict.has_key?(field)
  end

  defp invalid_for?(%{model: model, changeset_func: changeset}, field, value),
    do: invalid_for?(%{params: %{}, model: model, changeset_func: changeset}, field, value)
  defp invalid_for?(changeset, field, value),
    do: Dict.has_key?(changeset.errors, field)

  defp stringify_field(field) when is_atom(field),
    do: Atom.to_string(field)
  defp stringify_field(field) when is_binary(field), do: field

  defp stringify_keys(map) when is_map(map),
    do: Enum.into(map, %{}, fn({key, value}) ->
      {stringify_field(key), stringify_keys(value)}
    end)
  defp stringify_keys(value), do: value
end
