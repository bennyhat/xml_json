defmodule XmlJson.BadgerFish do
  @moduledoc """
  The BadgerFish implementation of XML <=> JSON

  http://www.sklar.com/badgerfish/
  """

  @doc """
  Serializes the given Map.

  Returns an `:ok` tuple with the Map serialized to XML

  ## Examples

      iex> XmlJson.BadgerFish.serialize(%{"alice" => %{"$" => "bob"}})
      {:ok, "<alice>bob</alice>"}

  """
  def serialize(object) do
    [{name, value}] = Map.to_list(object)

    xml =
      to_simple_form(value, name)
      |> Saxy.encode!()

    {:ok, xml}
  end

  @doc """
  Deserializes the given XML string.

  Returns an `:ok` tuple with the XML deserialized to a Map

  ## Examples

      iex> XmlJson.BadgerFish.deserialize("<alice>bob</alice>")
      {:ok, %{"alice" => %{"$" => "bob"}}}

  """
  def deserialize(xml) when is_binary(xml) do
    {:ok, element} = Saxy.parse_string(xml, XmlJson.SaxHandler, [])
    {:ok, %{element.name => walk_element(element)}}
  end

  defp to_simple_form(object, name, ns_keys \\ [])

  defp to_simple_form(object, name, ns_keys) when is_map(object) do
    attributes_object =
      Enum.filter(object, fn {k, _v} ->
        String.starts_with?(k, "@")
      end)
      |> Map.new()

    children_object = Map.drop(object, Map.keys(attributes_object) ++ ns_keys)

    attributes =
      Enum.map(attributes_object, &to_simple_attribute/1)
      |> List.flatten()
      |> Enum.reject(fn {k, _v} -> k in ns_keys end)

    new_ns_keys =
      Enum.filter(attributes, fn
        {"xmlns" <> _rest, _v} -> true
        _ -> false
      end)
      |> Enum.map(fn {k, _v} -> k end)

    child_ns_keys = new_ns_keys ++ ns_keys

    children =
      Enum.map(children_object, &to_simple_child(&1, child_ns_keys))
      |> List.flatten()

    {name, attributes, children}
  end

  defp to_simple_form(list, name, ns_keys) when is_list(list) do
    Enum.map(list, fn item -> to_simple_form(item, name, ns_keys) end)
  end

  defp to_simple_form(nil, name, _ns_keys) do
    {name, [], []}
  end

  defp to_simple_form(scalar, "$", _ns_keys) do
    {:characters, to_string(scalar)}
  end

  defp to_simple_form(scalar, name, _ns_keys) do
    {name, [], [{:characters, to_string(scalar)}]}
  end

  defp to_simple_child({k, v}, ns_keys), do: to_simple_form(v, k, ns_keys)

  defp to_simple_attribute({"@xmlns", value}) do
    Enum.map(value, fn
      {"$", v} -> {"xmlns", v}
      {k, v} -> {"xmlns:" <> k, v}
    end)
  end

  defp to_simple_attribute({name, value}) do
    {String.trim(name, "@"), value}
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
