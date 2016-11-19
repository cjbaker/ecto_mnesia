defmodule Ecto.Mnesia.Schema do
  @doc """
  Convert Ecto Schema struct to tuple that can be inserted to Mnesia.
  """
  def to_record(schema, params, table) do
    table = table |> Ecto.Mnesia.Table.get_name()
    fields = schema.__schema__(:fields)
    nilled_tuple = List.to_tuple([table | List.duplicate(nil, length(fields))])
    params
    |> List.foldl(nilled_tuple, fn ({k, v}, acc) ->
      :erlang.setelement(:string.str(fields, [k]) + 1, acc, cast_type(v))
    end)
  end

  def from_records(records, schema, fields, take, _preprocess_fn) do
    fields = fields
    |> unzip_fields(schema)

    take = take
    |> unzip_take(fields)

    records
    |> Enum.map(fn row -> from_record(schema.__struct__, List.zip([take, row])) end)
  end

  defp from_record(row, zip) do
    [List.foldr(zip, row, fn ({k, v}, acc) -> Map.update!(acc, k, fn _ -> v end) end)]
  end

  defp unzip_fields([{:&, [], [_, f, _]}], _),
    do: f
  defp unzip_fields(fields, schema),
    do: unzip_field(fields, schema, [])

  defp unzip_field([], _, acc),
    do: acc |> Enum.reverse
  defp unzip_field([{{:., [], [{:&, [], [0]}, field]}, _, _} | t], table, acc) do
    unzip_field(t, table, [field | acc])
  end

  defp unzip_take(%{0 => {:any, t}}, _), do: t
  defp unzip_take(_, fields), do: fields

  @doc """
  Cast types to compatible in Mensia.
  """
  def cast_type(%Decimal{coef: x, exp: y, sign: z}) do # TODO: Improve this cast and move to dumpers/loaders in `extensions/`
    case z do
      1 -> x * :math.pow(10, y)
      0 -> x * :math.pow(10, y) * -1
    end
  end
  def cast_type(x), do: x
end