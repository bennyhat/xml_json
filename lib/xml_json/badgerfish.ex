defmodule XmlJson.BadgerFish do
  @moduledoc """
  The BadgerFish implementation of XML <=> JSON

  http://www.sklar.com/badgerfish/
  """

  @default_opts %{
    exclude_namespaces: false,
    ns_keys: []
  }

  @doc """
  Serializes the given Map.

  Returns an `:ok` tuple with the Map serialized to XML

  ## Examples

      iex> XmlJson.BadgerFish.serialize(%{"alice" => %{"$" => "bob"}})
      {:ok, "<alice>bob</alice>"}

  """
  def serialize(object, opts \\ [])
  def serialize(object, opts) when not is_map(opts), do: serialize(object, Map.merge(@default_opts, Map.new(opts)))
  def serialize(object, opts) do
    [{name, value}] = Map.to_list(object)

    xml =
      to_simple_form(value, name, opts)
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
  def deserialize(xml) do
    {:ok, element} = Saxy.parse_string(xml, XmlJson.SaxHandler, [])
    {:ok, %{element.name => walk_element(element)}}
  end

  defp to_simple_form(object, name, opts)

  defp to_simple_form(object, name, opts) when is_map(object) do
    attributes =
      Enum.filter(object, &is_attribute_we_want?(&1, opts))
      |> Enum.map(&to_simple_attribute/1)
      |> List.flatten()
      |> Enum.reject(&is_namespace_we_have_seen?(&1, opts))

    child_opts = Map.merge(opts, %{
        ns_keys: seen_namespace_keys(attributes, opts)
      }
    )

    children =
      Enum.reject(object, &is_attribute?/1)
      |> Enum.map(&to_simple_child(&1, child_opts))
      |> List.flatten()

    {name, attributes, children}
  end

  defp to_simple_form(list, name, opts) when is_list(list) do
    Enum.map(list, fn item -> to_simple_form(item, name, opts) end)
  end

  defp to_simple_form(nil, name, _opts) do
    {name, [], []}
  end

  defp to_simple_form(scalar, "$", _opts) do
    {:characters, to_string(scalar)}
  end

  defp to_simple_form(scalar, name, _opts) do
    {name, [], [{:characters, to_string(scalar)}]}
  end

  defp to_simple_child({k, v}, opts), do: to_simple_form(v, k, opts)

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

  defp is_attribute?({key, _v}) do
    String.starts_with?(key, "@")
  end
  defp is_attribute_we_want?({k, _v} = kv, %{exclude_namespaces: true}) do
    is_attribute?(kv) and k != "@xmlns"
  end
  defp is_attribute_we_want?(kv, _opts), do: is_attribute?(kv)
  defp is_namespace_we_have_seen?({k, _v}, %{ns_keys: ns_keys}) do
    k in ns_keys
  end

  defp seen_namespace_keys(attributes, %{ns_keys: ns_keys}) do
    new_ns_keys =
      Enum.filter(attributes, fn
        {"xmlns" <> _rest, _v} -> true
        _ -> false
      end)
      |> Enum.map(fn {k, _v} -> k end)

    new_ns_keys ++ ns_keys
  end

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
