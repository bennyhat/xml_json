defmodule XmlJson.Parker.Deserializer do
  @moduledoc """
  Parker implementation of deserialization from a Xml into Map
  """

  @type parker_deserializer_options ::
          %{
            preserve_root: boolean()
          }
          | [
              preserve_root: boolean()
            ]

  @default_opts %{
    preserve_root: false
  }

  @spec deserialize(binary(), parker_deserializer_options()) :: {:ok, map()}
  def deserialize(xml, opts) do
    merged_options = merge_default_options(opts)
    {:ok, element} = Saxy.parse_string(xml, XmlJson.SaxHandler, [])

    walk_element(element)
    |> maybe_preserve_root(element, merged_options)
  end

  defp maybe_preserve_root(element, original, %{preserve_root: true}),
    do: {:ok, %{original.name => element}}

  defp maybe_preserve_root(element, _original, _opts), do: {:ok, element}

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
      _ -> parker
    end
  end

  defp maybe_hoist_children(parker), do: parker

  defp merge_default_options(provided) when is_map(provided) do
    Map.merge(@default_opts, provided)
  end

  defp merge_default_options(provided) do
    merge_default_options(Map.new(provided))
  end
end
