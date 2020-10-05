defmodule XmlJson.Parker do
  @moduledoc """
  The Parker implementation of XML <=> JSON

  https://developer.mozilla.org/en-US/docs/Archive/JXON#The_Parker_Convention
  """

  @doc """
  Serializes the given Map.
  Takes an option (`preserve_root`, defaults to "root") for what property to hoist or inject as the root element

  Returns an `:ok` tuple with the Map serialized to XML

  ## Examples

      iex> XmlJson.Parker.serialize(%{"alice" => "bob"}, preserve_root: "alice")
      {:ok, "<alice>bob</alice>"}

  """
  def serialize(value, opts \\ [])

  def serialize(object, opts) when is_map(object) do
    name = Keyword.get(opts, :preserve_root, "root")
    value = Map.get(object, name, object)

    xml =
      to_simple_form(value, name)
      |> Saxy.encode!()

    {:ok, xml}
  end

  def serialize(list, _opts) when is_list(list), do: {:error, :cannot_serialize_root_list}
  def serialize(_scalar, _opts), do: {:error, :cannot_serialize_root_scalar}

  @doc """
  Deserializes the given XML string.
  Takes an option (`preserve_root`, defaults to false) for hoisting the root element or not

  Returns an `:ok` tuple with the XML serialized to a Map

  ## Examples

      iex> XmlJson.Parker.deserialize("<alice>bob</alice>", preserve_root: true)
      {:ok, %{"alice" => "bob"}}

  """
  def deserialize(xml, opts \\ []) when is_binary(xml) do
    preserve_root = Keyword.get(opts, :preserve_root, false)

    {:ok, element} = Saxy.parse_string(xml, XmlJson.SaxHandler, [])
    walked_element = walk_element(element)

    if preserve_root do
      {:ok, %{element.name => walked_element}}
    else
      {:ok, walked_element}
    end
  end

  defp to_simple_form(object, name) when is_map(object) do
    children =
      Enum.map(object, fn {k, v} -> to_simple_form(v, k) end)
      |> List.flatten()

    {name, [], children}
  end

  defp to_simple_form(list, name) when is_list(list) do
    Enum.map(list, fn item -> to_simple_form(item, name) end)
  end

  defp to_simple_form(nil, name) do
    {name, [], []}
  end

  defp to_simple_form(scalar, name) do
    {name, [], [{:characters, to_string(scalar)}]}
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
