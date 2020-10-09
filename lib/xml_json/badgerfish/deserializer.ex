defmodule XmlJson.BadgerFish.Deserializer do
  @moduledoc """
  Badgerfish implementation of deserialization from a Xml into Map
  """

  alias XmlJson.SaxHandler

  @spec deserialize(binary(), map()) :: {:ok, map()}
  def deserialize(xml, opts) do
    case SaxHandler.parse_string(xml) do
      {:ok, element} ->
        {:ok, %{element.name => walk_element(element, opts)}}
      error -> error
    end
  end

  defp walk_element(element, opts) do
    update_children(%{}, element, opts)
    |> update_text(element)
    |> update_attributes(element, opts)
  end

  defp update_children(badgerfish, %{children: children}, opts) do
    accumulate_children(badgerfish, children, opts)
    |> Map.delete("$")
  end

  defp update_children(badgerfish, _no_children, _opts), do: badgerfish
  defp update_text(badgerfish, %{text: ""}), do: badgerfish
  defp update_text(badgerfish, %{text: "\n"}), do: badgerfish

  defp update_text(badgerfish, %{text: text}) do
    Map.put(badgerfish, "$", text)
  end

  defp update_text(badgerfish, _empty_element), do: badgerfish

  defp update_attributes(badgerfish, element, opts) do
    Enum.reduce(element.attributes, badgerfish, fn {k, v}, a ->
      {k, v} = handle_namespaces(k, v)

      Map.update(a, "@" <> k, v, fn current ->
        Map.merge(current, v)
      end)
    end)
    |> maybe_exclude_namespaces(opts)
  end

  defp maybe_exclude_namespaces(attributes, %{exclude_namespaces: true}) do
    Map.delete(attributes, "@xmlns")
  end

  defp maybe_exclude_namespaces(attributes, _opts), do: attributes

  defp handle_namespaces("xmlns", value) do
    {"xmlns", %{"$" => value}}
  end

  defp handle_namespaces("xmlns:" <> rest, value) do
    {"xmlns", %{rest => value}}
  end

  defp handle_namespaces(key, value), do: {key, value}

  defp accumulate_children(badgerfish, children, opts) do
    Enum.reduce(children, badgerfish, fn element, object ->
      walked = walk_element(element, opts)

      Map.update(object, element.name, walked, &accumulate_list(&1, walked))
    end)
  end

  defp accumulate_list(value, walked) do
    List.wrap(value) ++ [walked]
  end
end
