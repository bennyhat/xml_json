defmodule XmlJson.BadgerFish do
  @moduledoc """
  The BadgerFish implementation of XML <=> JSON

  http://badgerfish.ning.com/
  """

  def deserialize(xml) when is_binary(xml) do
    {:ok, element} = Saxy.parse_string(xml, XmlJson.SaxHandler, [])
    {:ok, %{element.name => walk_element(element)}}
  end

  defp update_children(badgerfish, %{children: children}) do
    Enum.reduce(children, badgerfish, fn i, a ->
      walked = walk_element(i)

      Map.update(a, i.name, walked, fn thing ->
        wrapped_thing = List.wrap(thing)
        wrapped_thing ++ [walked]
      end)
    end)
    |> Map.delete("$")
  end
  defp update_children(badgerfish, _no_children), do: badgerfish

  defp update_text(badgerfish, %{text: ""}), do: badgerfish

  defp update_text(badgerfish, %{text: text}) do
    Map.put(badgerfish, "$", text)
  end

  defp update_text(badgerfish, _empty_element), do: badgerfish

  defp update_attributes(badgerfish, element) do
    Enum.reduce(element.attributes, badgerfish, fn {k, v}, a ->
      {k, v} = handle_namespaces(k, v)

      Map.update(a, "@" <> k, v, fn current ->
        Map.merge(current, v)
      end)
    end)
  end

  defp walk_element(element) do
    update_children(%{}, element)
    |> update_text(element)
    |> update_attributes(element)
  end

  defp handle_namespaces("xmlns", value) do
    {"xmlns", %{"$" => value}}
  end

  defp handle_namespaces("xmlns:" <> rest, value) do
    {"xmlns", %{rest => value}}
  end

  defp handle_namespaces(key, value), do: {key, value}
end
