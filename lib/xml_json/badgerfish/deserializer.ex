defmodule XmlJson.BadgerFish.Deserializer do
  @moduledoc """
  Badgerfish implementation of deserialization from a Xml into Map
  """

  def deserialize(xml, _opts) do
    {:ok, element} = Saxy.parse_string(xml, XmlJson.SaxHandler, [])
    {:ok, %{element.name => walk_element(element)}}
  end

  defp walk_element(element) do
    update_children(%{}, element)
    |> update_text(element)
    |> update_attributes(element)
  end

  defp update_children(badgerfish, %{children: children}) do
    accumulate_children(badgerfish, children)
    |> Map.delete("$")
  end

  defp update_children(badgerfish, _no_children), do: badgerfish
  defp update_text(badgerfish, %{text: ""}), do: badgerfish
  defp update_text(badgerfish, %{text: "\n"}), do: badgerfish

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

  defp handle_namespaces("xmlns", value) do
    {"xmlns", %{"$" => value}}
  end

  defp handle_namespaces("xmlns:" <> rest, value) do
    {"xmlns", %{rest => value}}
  end

  defp handle_namespaces(key, value), do: {key, value}

  defp accumulate_children(badgerfish, children) do
    Enum.reduce(children, badgerfish, fn element, object ->
      walked = walk_element(element)

      Map.update(object, element.name, walked, &accumulate_list(&1, walked))
    end)
  end

  defp accumulate_list(value, walked) do
    List.wrap(value) ++ [walked]
  end
end
