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

  Returns an `:ok` tuple with a Map serialized to XML

  ## Examples

      iex> XmlJson.BadgerFish.serialize(%{"alice" => %{"$" => "bob"}})
      {:ok, "<alice>bob</alice>"}

  """
  def serialize(object, opts \\ [])
  def serialize(object, opts), do: Serializer.serialize(object, merge_default_options(opts))

  @doc """
  Deserializes the given XML string.

  Returns an `:ok` tuple with the XML deserialized to a Map

  ## Examples

      iex> XmlJson.BadgerFish.deserialize("<alice>bob</alice>")
      {:ok, %{"alice" => %{"$" => "bob"}}}

  """
  def deserialize(xml, opts \\ [])
  def deserialize(xml, opts), do: Deserializer.deserialize(xml, merge_default_options(opts))

  defp merge_default_options(provided) when is_map(provided) do
    Map.merge(@default_opts, provided)
  end
  defp merge_default_options(provided) do
    merge_default_options(Map.new(provided))
  end
end
