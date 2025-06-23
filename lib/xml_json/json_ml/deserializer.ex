defmodule XmlJson.JsonML.Deserializer do
  @moduledoc """
  JsonML implementation of deserialization from Xml into a List
  """

  alias XmlJson.SaxHandler

  @spec deserialize(binary(), map()) :: {:ok, map()} | {:error, Saxy.ParseError.t()}
  def deserialize(xml, opts) do
    opts = Map.merge(opts, %{propagate_namespaces: false})

    case SaxHandler.parse_string(xml, opts) do
      {:ok, element} ->
        {:ok, walk_element(element, opts)}

      error ->
        error
    end
  end

  defp walk_element(%{name: name} = element, opts) do
    attributes = attributes(element, opts)
    children = children(element, opts)

    [name]
    |> append(attributes)
    |> append(children)
  end

  defp walk_element(%{text: ""}, _opts), do: nil
  defp walk_element(%{text: "\n"}, _opts), do: nil
  defp walk_element(%{text: text}, _opts), do: text
  defp walk_element(_, _opts), do: nil

  defp children(%{children: children}, opts) do
    children
    |> Enum.map(fn child ->
      walk_element(child, opts)
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp children(_no_children, _opts), do: []

  defp attributes(%{attributes: attributes}, opts) do
    attributes
    |> maybe_exclude_namespaces(opts)
    |> Map.new()
  end

  defp attributes(_no_attributes, _opts), do: nil

  defp maybe_exclude_namespaces(attributes, %{exclude_namespaces: true}) do
    Enum.reject(attributes, fn {k, _v} ->
      String.starts_with?(k, "xmlns")
    end)
  end

  defp maybe_exclude_namespaces(attributes, _opts), do: attributes

  defp append(list, nil), do: list
  defp append(list, empty_map) when empty_map == %{}, do: list

  defp append(list, item) when is_list(item) do
    Enum.concat([list, item])
  end

  defp append(list, item) do
    list
    |> Enum.reverse()
    |> List.insert_at(0, item)
    |> Enum.reverse()
  end
end
