defmodule XmlJson.AwsApi.Serializer do
  @moduledoc """
  An AWS implementation of serialization from a Map into Xml
  """

  alias XmlJson.SaxHandler

  @spec serialize(map(), map()) :: {:ok, binary()} | {:error, term()}
  def serialize(object, opts) do
    [{name, value}] = Map.to_list(object)
    simple_form = to_simple_form(value, name, opts)

    case SaxHandler.encode(simple_form) do
      {:ok, _} = ok -> ok
      error -> error
    end
  end

  defp to_simple_form(object, name, opts)

  defp to_simple_form(object, name, opts) when is_map(object) do
    children =
      Enum.map(object, &to_simple_child(&1, opts))
      |> List.flatten()

    {name, [], children}
  end

  defp to_simple_form(list, name, opts) when is_list(list) do
    {list_element_name, child_opts} = cycle_list_name(opts)

    children =
      Enum.reduce(list, [], fn item, acc ->
        [to_simple_form(item, list_element_name, child_opts) | acc]
      end)

    if list_element_name == "" do
      children = Enum.map(children, fn {_, _, c} -> c end)
      |> List.flatten()

      {name, [], Enum.reverse(children)}
    else
      {name, [], Enum.reverse(children)}
    end
  end

  defp to_simple_form(nil, name, _opts) do
    {name, [], []}
  end

  defp to_simple_form(scalar, name, _opts) do
    {name, [], [{:characters, to_string(scalar)}]}
  end

  defp to_simple_child({k, v}, opts), do: to_simple_form(v, k, opts)

  defp cycle_list_name(%{list_element_names: lens} = opts) do
    [list_element_name | rest] = lens
    child_lens = rest ++ [list_element_name]

    {list_element_name, Map.put(opts, :list_element_names, child_lens)}
  end
end
