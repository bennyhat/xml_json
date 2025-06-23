defmodule XmlJson.AwsApi.Deserializer do
  @moduledoc """
  AWS implementation for deserialization from Xml into a Map
  """

  alias XmlJson.SaxHandler

  @spec deserialize(binary(), map()) :: {:ok, map()} | {:error, Saxy.ParseError.t()}
  def deserialize(xml, opts) do
    case SaxHandler.parse_string(xml, opts) do
      {:ok, element} ->
        {:ok, %{element.name => walk_element(element, opts)}}

      error ->
        error
    end
  end

  defp walk_element(element, opts) do
    update_children(%{}, element, opts)
    |> update_attributes(element, opts)
  end

  defp update_children(aws, %{children: children}, opts) do
    aws
    |> accumulate_children(children, opts)
    |> text_or_elements()
    |> maybe_hoist_children(opts)
  end

  defp update_children(_aws, _no_children, _opts), do: nil

  defp text_or_elements(%{"$" => text} = children) do
    case trim(text) do
      "" ->
        delete_fully(children, "$")

      trimmed ->
        trimmed
    end
  end

  defp text_or_elements(children), do: children

  defp delete_fully(map, key) do
    case Map.delete(map, key) do
      new_map when map_size(new_map) == 0 -> nil
      new_map -> new_map
    end
  end

  defp update_attributes(aws, _ignored, _opts), do: aws

  defp trim(text) when is_binary(text) do
    String.trim(text)
  end

  defp trim(value), do: value

  defp accumulate_children(aws, children, opts) do
    Enum.reduce(children, aws, &accumulate_child(&1, &2, opts))
  end

  defp maybe_hoist_children(map, %{list_element_names: names} = _opts)
       when is_map(map) and map_size(map) == 1 do
    [{name, value}] = Map.to_list(map)

    if name in names do
      List.wrap(value)
    else
      map
    end
  end

  defp maybe_hoist_children(value, _opts) do
    value
  end

  defp accumulate_child(%{name: name} = element, object, opts) do
    walked = walk_element(element, opts)

    Map.update(object, name, walked, &accumulate_list(&1, walked))
  end

  defp accumulate_child(%{text: text}, object, _opts) do
    Map.update(object, "$", text, fn current -> current <> " " <> text end)
  end

  defp accumulate_list(value, walked) do
    List.wrap(value) ++ [walked]
  end
end
