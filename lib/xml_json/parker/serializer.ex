defmodule XmlJson.Parker.Serializer do
  @moduledoc """
  Parker implementation of deserialization from a Xml into Map
  """

  alias XmlJson.SaxHandler

  @spec serialize(map(), map()) :: {:ok, binary()}
  def serialize(object, opts) do
    {name, value} = root_map_form(object, opts)
    simple_form = to_simple_form(value, name)

    case SaxHandler.encode(simple_form) do
      {:ok, _} = ok -> ok
      error -> error
    end
  end

  defp root_map_form(object, %{preserve_root: false} = opts) do
    root_map_form(object, Map.put(opts, :preserve_root, "root"))
  end
  defp root_map_form(object, %{preserve_root: name}) when is_map(object) do
    value = Map.get(object, name, object)
    {name, value}
  end

  defp root_map_form(list, %{preserve_root: name}) when is_list(list) do
    {name, Enum.join(list, ",")}
  end

  defp root_map_form(value, %{preserve_root: name}) do
    {name, to_string(value)}
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
end
