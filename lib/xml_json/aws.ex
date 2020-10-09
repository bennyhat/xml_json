defmodule XmlJson.Aws do
  @moduledoc """
  An AWS implementation of XML <=> JSON

  Based on various conventions encountered in AWS XML-based APIs
  """

  alias XmlJson.Aws.Deserializer
  # alias XmlJson.BadgerFish.Serializer

  # @type badgerfish_options ::
  #         %{
  #           exclude_namespaces: boolean()
  #         }
  #         | [
  #             exclude_namespaces: boolean()
  #           ]

  @default_opts %{
    list_element_names: ["member"]
  }

  # @doc """
  # Serializes the given Map.

  # Returns an `:ok` tuple with a Map serialized to XML

  # ## Examples

  #     iex> XmlJson.BadgerFish.serialize(%{"alice" => %{"$" => "bob"}})
  #     {:ok, "<alice>bob</alice>"}

  #     iex> XmlJson.BadgerFish.serialize(%{"alice" => %{"$" => "bob", "@xmlns" => %{"$" => "https://default.example.com"}}}, exclude_namespaces: true)
  #     {:ok, "<alice>bob</alice>"}

  # """
  # @spec serialize(map(), badgerfish_options()) :: {:ok, binary()}
  # def serialize(object, opts \\ [])
  # def serialize(object, opts), do: Serializer.serialize(object, merge_default_options(opts))

  # @spec serialize!(map(), badgerfish_options()) :: binary()
  # def serialize!(map, opts \\ [])

  # def serialize!(map, opts) do
  #   case serialize(map, opts) do
  #     {:ok, xml} -> xml
  #     {:error, reason} -> raise reason
  #   end
  # end

  @doc """
  Deserializes the given XML string.

  Returns an `:ok` tuple with the XML deserialized to a Map

  ## Examples

      iex> XmlJson.BadgerFish.deserialize("<alice>bob</alice>")
      {:ok, %{"alice" => %{"$" => "bob"}}}

      iex> XmlJson.BadgerFish.deserialize("<alice xmlns=\\"https://default.example.com\\">bob</alice>", exclude_namespaces: true)
      {:ok, %{"alice" => %{"$" => "bob"}}}

  """
  @spec deserialize(binary(), map()) :: {:ok, map()}
  def deserialize(xml, opts \\ [])
  def deserialize(xml, opts) do
    Deserializer.deserialize(xml, merge_default_options(opts))
  end

  # @spec deserialize!(binary(), badgerfish_options()) :: map()
  # def deserialize!(xml, opts \\ [])

  # def deserialize!(xml, opts) do
  #   case deserialize(xml, opts) do
  #     {:ok, element} -> element
  #     {:error, reason} -> raise reason
  #   end
  # end

  defp merge_default_options(provided) when is_map(provided) do
    Map.merge(@default_opts, provided)
  end

  defp merge_default_options(provided) do
    merge_default_options(Map.new(provided))
  end
end
