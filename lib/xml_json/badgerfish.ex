defmodule XmlJson.BadgerFish do
  @moduledoc """
  The BadgerFish implementation of XML <=> JSON

  http://www.sklar.com/badgerfish/
  """

  alias XmlJson.BadgerFish.Deserializer
  alias XmlJson.BadgerFish.Serializer

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
  def serialize(object, opts) when not is_map(opts), do: Serializer.serialize(object, Map.merge(@default_opts, Map.new(opts)))
  def serialize(object, opts) when is_map(opts), do: Serializer.serialize(object, Map.merge(@default_opts, opts))

  @doc """
  Deserializes the given XML string.

  Returns an `:ok` tuple with the XML deserialized to a Map

  ## Examples

      iex> XmlJson.BadgerFish.deserialize("<alice>bob</alice>")
      {:ok, %{"alice" => %{"$" => "bob"}}}

  """
  def deserialize(xml, opts \\ [])
  def deserialize(xml, opts) when not is_map(opts), do: Deserializer.deserialize(xml, Map.merge(@default_opts, Map.new(opts)))
  def deserialize(xml, opts) when is_map(opts), do: Deserializer.deserialize(xml, Map.merge(@default_opts, opts))

end
