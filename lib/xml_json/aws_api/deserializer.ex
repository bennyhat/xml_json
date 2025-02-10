defmodule XmlJson.AwsApi.Deserializer do
  @moduledoc """
  AWS implementation for deserialization from a Xml into Map
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
    |> update_text(element)
    |> update_attributes(element, opts)
  end

  defp update_children(aws, %{children: children}, opts) do
    accumulate_children(aws, children, opts)
  end

  defp update_children(_aws, _no_children, _opts), do: nil

  defp update_text(aws, %{text: ""}), do: aws
  defp update_text(aws, %{text: "\n"}), do: aws
  defp update_text(_aws, %{text: text}) when is_binary(text), do: handle_empty(text)
  defp update_text(_aws, %{text: text}), do: text
  defp update_text(aws, _empty_element), do: aws

  defp update_attributes(aws, _ignored, _opts), do: aws

  defp handle_empty(text) do
    case String.trim(text) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp accumulate_children(aws, children, %{list_element_names: names} = opts) do
    case Enum.reduce(children, aws, &accumulate_child(&1, &2, opts)) do
      map when map_size(map) == 1 ->
        [{name, value}] = Map.to_list(map)

        if name in names do
          List.wrap(value)
        else
          map
        end

      map ->
        map
    end
  end

  defp accumulate_child(element, object, opts) do
    walked = walk_element(element, opts)

    Map.update(object, element.name, walked, &accumulate_list(&1, walked))
  end

  defp accumulate_list(value, walked) do
    List.wrap(value) ++ [walked]
  end
end
