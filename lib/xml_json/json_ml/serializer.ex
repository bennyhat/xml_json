defmodule XmlJson.JsonML.Serializer do
  @moduledoc """
  JsonML implementation of serialization from a List into Xml
  """

  alias XmlJson.SaxHandler

  @spec serialize(list(), map()) :: {:ok, binary()} | {:error, term()}
  def serialize(list, opts) do
    simple_form = to_simple_form(list, opts)

    case SaxHandler.encode(simple_form) do
      {:ok, _} = ok -> ok
      error -> error
    end
  end

  defp to_simple_form(list, opts)

  defp to_simple_form(list, opts) when is_list(list) do
    [name | rest] = list

    element =
      Enum.reduce(rest, %{}, fn item, acc ->
        case to_simple_form(item, opts) do
          {:attributes, attributes} ->
            Map.put(acc, :attributes, attributes)

          {:characters, _c} = child ->
            Map.update(acc, :children, [child], fn children ->
              children ++ [child]
            end)

          {_name, _attr, _children} = child ->
            Map.update(acc, :children, [child], fn children ->
              children ++ [child]
            end)
        end
      end)

    {name, Map.get(element, :attributes, []), Map.get(element, :children, [])}
  end

  defp to_simple_form(map, opts) when is_map(map) do
    map =
      map
      |> Map.to_list()
      |> maybe_exclude_namespaces(opts)

    {:attributes, map}
  end

  defp to_simple_form(scalar, _opts) do
    {:characters, to_string(scalar)}
  end

  defp maybe_exclude_namespaces(map, %{exclude_namespaces: true}) do
    Enum.reject(map, fn {k, _v} ->
      String.starts_with?(k, "xmlns")
    end)
  end

  defp maybe_exclude_namespaces(map, _), do: map
end
