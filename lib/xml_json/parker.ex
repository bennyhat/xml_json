defmodule XmlJson.Parker do
  @moduledoc """
  The Parker implementation of XML <=> JSON

  https://developer.mozilla.org/en-US/docs/Archive/JXON#The_Parker_Convention
  """

  def serialize(value, opts \\ [])
  def serialize(object, opts) when is_map(object) do
    name = Keyword.get(opts, :root_name, "root")
    xml = to_simple_form(object, name)
    |> Saxy.encode!()
    {:ok, xml}
  end
  def serialize(list, opts) when is_list(list), do: {:error, :cannot_serialize_root_list}
  def serialize(_scalar, opts), do: {:error, :cannot_serialize_root_scalar}

  defp to_simple_form(object, name) when is_map(object) do
    children = Enum.map(object, fn {k, v} -> to_simple_form(v, k) end)
    {name, [], children}
  end
  defp to_simple_form(list, name) when is_list(list) do
    Enum.map(list, fn item -> to_simple_form(name, item) end)
  end
  defp to_simple_form(scalar, name) do
    {name, [], [scalar]}
  end

  def deserialize(xml) when is_binary(xml) do
    {:ok, element} = Saxy.parse_string(xml, XmlJson.SaxHandler, [])
    {:ok, walk_element(element)}
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
      _ -> parker
    end
  end

  defp maybe_hoist_children(parker), do: parker
end
