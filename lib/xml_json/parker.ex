defmodule XmlJson.Parker do
  @moduledoc """
  The Parker implementation of XML <=> JSON

  https://developer.mozilla.org/en-US/docs/Archive/JXON#The_Parker_Convention
  """

  alias XmlJson.Parker.Deserializer
  alias XmlJson.Parker.Serializer

  @doc """
  Serializes the given Map.
  Takes an option (`preserve_root`, defaults to "root") for what property to hoist or inject as the root element

  Returns an `:ok` tuple with the Map serialized to XML

  ## Examples

      iex> XmlJson.Parker.serialize(%{"alice" => "bob"})
      {:ok, "<root><alice>bob</alice></root>"}

      iex> XmlJson.Parker.serialize(%{"alice" => "bob"}, preserve_root: "alice")
      {:ok, "<alice>bob</alice>"}

  """
  def serialize(object, opts \\ [])
  def serialize(object, opts), do: Serializer.serialize(object, opts)

  @doc """
  Deserializes the given XML string.
  Takes an option (`preserve_root`, defaults to false) for hoisting the root element or not

  Returns an `:ok` tuple with the XML deserialized to a Map

  ## Examples

      iex> XmlJson.Parker.deserialize("<alice>bob</alice>")
      {:ok, "bob"}

      iex> XmlJson.Parker.deserialize("<alice>bob</alice>", preserve_root: true)
      {:ok, %{"alice" => "bob"}}

  """
  def deserialize(xml, opts \\ [])
  def deserialize(xml, opts), do: Deserializer.deserialize(xml, opts)

end
