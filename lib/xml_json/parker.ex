defmodule XmlJson.Parker do
  @moduledoc """
  The Parker implementation of XML <=> JSON

  https://developer.mozilla.org/en-US/docs/Archive/JXON#The_Parker_Convention
  """

  alias XmlJson.Parker.Deserializer
  alias XmlJson.Parker.Serializer

  @type parker_options ::
          %{
            preserve_root: boolean() | binary()
          }
          | [
              preserve_root: boolean() | binary()
            ]

  @default_opts %{
    preserve_root: false
  }

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
  @spec serialize(map(), parker_options()) :: {:ok, binary()} | {:error, term()}
  def serialize(object, opts \\ [])
  def serialize(object, opts), do: Serializer.serialize(object, merge_default_options(opts))

  @spec serialize!(map(), parker_options()) :: binary()
  def serialize!(map, opts \\ [])

  def serialize!(map, opts) do
    case serialize(map, opts) do
      {:ok, xml} -> xml
      {:error, reason} -> raise reason
    end
  end

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
  @spec deserialize(binary(), parker_options()) :: {:ok, map()} | {:error, term()}
  def deserialize(xml, opts \\ [])
  def deserialize(xml, opts), do: Deserializer.deserialize(xml, merge_default_options(opts))

  @spec deserialize!(binary(), parker_options()) :: map()
  def deserialize!(xml, opts \\ [])

  def deserialize!(xml, opts) do
    case deserialize(xml, opts) do
      {:ok, element} -> element
      {:error, reason} -> raise reason
    end
  end

  defp merge_default_options(provided) when is_map(provided) do
    Map.merge(@default_opts, provided)
  end

  defp merge_default_options(provided) do
    merge_default_options(Map.new(provided))
  end
end
