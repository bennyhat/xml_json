defmodule XmlJson.AwsApi.ParamsSerializer do
  @moduledoc """
  An AWS implementation of serialization from a Map into Request Params
  """

  @spec serialize(map(), map()) :: {:ok, map()} | {:error, term()}
  def serialize(object, opts) do
    params =
      to_params("", object, opts)
      |> List.flatten()
      |> Map.new()

    {:ok, params}

  rescue
    e -> {:error, e}
  end

  defp to_params(prefix, map, opts) when is_map(map) do
    Enum.map(map, &to_param(&1, prefix, opts))
  end

  defp to_params(prefix, value, _opts) do
    {String.trim_trailing(prefix, "."), value}
  end

  defp to_param({k, v}, prefix, opts) when is_list(v) do
    {list_element_name, child_opts} = cycle_list_name(opts)

    Enum.with_index(v, 1)
    |> Enum.map(fn {v, vi} ->
      to_params(
        prefix <> k <> "." <> list_element_name <> "." <> to_string(vi) <> ".",
        v,
        child_opts
      )
    end)
  end

  defp to_param({k, v}, prefix, opts) when is_map(v) do
    to_params(prefix <> k <> ".", v, opts)
  end

  defp to_param({k, v}, prefix, _opts) do
    {prefix <> k, v}
  end

  defp cycle_list_name(%{list_element_names: lens} = opts) do
    [list_element_name | rest] = lens
    child_lens = rest ++ [list_element_name]

    {list_element_name, Map.put(opts, :list_element_names, child_lens)}
  end
end
