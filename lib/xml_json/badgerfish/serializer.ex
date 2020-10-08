defmodule XmlJson.BadgerFish.Serializer do
  @moduledoc """
  Badgerfish implementation of serialization from a Map into Xml
  """

  def serialize(object, opts) do
    [{name, value}] = Map.to_list(object)

    xml =
      to_simple_form(value, name, opts)
      |> Saxy.encode!()

    {:ok, xml}
  end

  defp to_simple_form(object, name, opts)

  defp to_simple_form(object, name, opts) when is_map(object) do
    attributes =
      Enum.filter(object, &is_attribute_we_want?(&1, opts))
      |> Enum.map(&to_simple_attribute/1)
      |> List.flatten()
      |> Enum.reject(&is_namespace_we_have_seen?(&1, opts))

    child_opts =
      Map.merge(opts, %{
        ns_keys: seen_namespace_keys(attributes, opts)
      })

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
end
