defmodule XmlJson.Parker.Deserializer do
  @moduledoc """
  Parker implementation of deserialization from a Xml into Map
  """

  alias XmlJson.SaxHandler

  @spec deserialize(binary(), map()) :: {:ok, map()} | {:error, Saxy.ParseError.t()}
  def deserialize(xml, opts) do
    case SaxHandler.parse_string(xml) do
      {:ok, element} ->
        walk_element(element)
        |> maybe_preserve_root(element, opts)

      error ->
        error
    end
  end

  defp walk_element(element) do
    update_children(%{}, element)
    |> update_text(element)
    |> update_attributes(element)
  end

  defp update_children(_parker, %{children: children}) do
    accumulate_children(children)
    |> maybe_hoist_children()
  end

  defp update_children(_parker, _no_children), do: nil
  defp update_text(nil, %{text: ""}), do: nil
  defp update_text(nil, %{text: text}), do: text
  defp update_text(parker, _ignored), do: parker
  defp update_attributes(parker, _ignored), do: parker

  defp accumulate_children(children) do
    Enum.reduce(children, %{}, fn i, a ->
      walked = walk_element(i)

      Map.update(a, i.name, walked, &accumulate_list(&1, walked))
    end)
  end

  defp accumulate_list(value, walked) do
    List.wrap(value) ++ [walked]
  end

  defp maybe_hoist_children(parker) when map_size(parker) == 1 do
    case Map.values(parker) do
      [list] when is_list(list) -> list
      [map] when is_map(map) -> 
        case Map.values(map) do 
          [nil] -> []
          _ -> [map]  
        end
      _ -> parker
    end
 end

  defp maybe_hoist_children(parker), do: parker

  defp maybe_preserve_root(element, original, %{preserve_root: true}),
    do: {:ok, %{original.name => element}}

  defp maybe_preserve_root(element, _original, _opts), do: {:ok, element}
end
