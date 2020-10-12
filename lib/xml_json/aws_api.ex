defmodule XmlJson.AwsApi do
  @moduledoc """
  An AWS implementation of XML <=> JSON

  Based on various conventions encountered in AWS XML-based APIs
  """

  alias XmlJson.AwsApi.Deserializer
  alias XmlJson.AwsApi.Serializer
  alias XmlJson.AwsApi.ParamsSerializer

  @type aws_api_options ::
          %{
            list_element_names: list(binary())
          }
          | [
              list_element_names: list(binary())
            ]

  @default_opts %{
    list_element_names: ["member"]
  }

  @doc """
  Serializes the given Map.

  Returns an `:ok` tuple with a Map serialized to XML

  ## Examples

      iex> XmlJson.AwsApi.serialize(%{"alice" => "bob"})
      {:ok, "<alice>bob</alice>"}

      iex> XmlJson.AwsApi.serialize(%{"alice" => ["bob", "jane"]})
      {:ok, "<alice><member>bob</member><member>jane</member></alice>"}

      iex> XmlJson.AwsApi.serialize(%{"alice" => [%{"name" => "bob"}, %{"name" => "jane"}]}, list_element_names: [""])
      {:ok, "<alice><name>bob</name><name>jane</name></alice>"}
  """
  @spec serialize(map(), aws_api_options()) :: {:ok, binary()} | {:error, term()}
  def serialize(object, opts \\ [])

  def serialize(object, opts),
    do: Serializer.serialize(object, merge_default_options(opts))

  @spec serialize!(map(), aws_api_options()) :: binary()
  def serialize!(map, opts \\ [])

  def serialize!(map, opts) do
    case serialize(map, opts) do
      {:ok, xml} -> xml
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Serializes the given Map as a set request parameters.

  Returns an `:ok` tuple with a Map serialized to a flattened Map

  ## Examples

      iex> XmlJson.AwsApi.serialize_as_params(%{"alice" => "bob"})
      {:ok, %{"alice" => "bob"}}

      iex> XmlJson.AwsApi.serialize_as_params(%{"alice" => ["bob", "jane"]})
      {:ok, %{"alice.member.1" => "bob", "alice.member.2" => "jane"}}

      iex> XmlJson.AwsApi.serialize_as_params(%{"alice" => ["bob", "jane"]}, list_element_names: [""])
      {:ok, %{"alice.1" => "bob", "alice.2" => "jane"}}

  """
  @spec serialize_as_params(map(), aws_api_options()) :: {:ok, map()} | {:error, term()}
  def serialize_as_params(object, opts \\ [])

  def serialize_as_params(object, opts),
    do: ParamsSerializer.serialize(object, merge_default_options(opts))

  @spec serialize_as_params!(map(), aws_api_options()) :: map()
  def serialize_as_params!(map, opts \\ [])

  def serialize_as_params!(map, opts) do
    case serialize_as_params(map, opts) do
      {:ok, xml} -> xml
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Deserializes the given XML string.

  Returns an `:ok` tuple with the XML deserialized to a Map

  ## Examples

      iex> XmlJson.AwsApi.deserialize("<alice>bob</alice>")
      {:ok, %{"alice" => "bob"}}

      iex> XmlJson.AwsApi.deserialize("<alice><member>bob</member></alice>")
      {:ok, %{"alice" => ["bob"]}}

  """
  @spec deserialize(binary(), aws_api_options()) :: {:ok, map()} | {:error, term()}
  def deserialize(xml, opts \\ [])

  def deserialize(xml, opts) do
    Deserializer.deserialize(xml, merge_default_options(opts))
  end

  @spec deserialize!(binary(), aws_api_options()) :: map()
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
