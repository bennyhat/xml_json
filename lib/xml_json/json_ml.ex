defmodule XmlJson.JsonML do
  @moduledoc """
  The JsonML implementation of XML <=> JSON

  This is a JSON representation of XML that is designed to preserve ordering
  as many XSDs enforce that through the use of `xs:sequence`.

  https://www.jsonml.org/syntax/
  """

  alias XmlJson.JsonML.Deserializer
  alias XmlJson.JsonML.Serializer

  @type json_ml_options ::
          %{
            exclude_namespaces: boolean(),
            try_parse: boolean()
          }
          | [
              exclude_namespaces: boolean(),
              try_parse: boolean()
            ]

  @default_opts %{
    exclude_namespaces: false,
    ns_keys: [],
    try_parse: true
  }

  @doc """
  Serializes the given List.

  Returns an `:ok` tuple with a List serialized to XML

  ## Examples

      iex> XmlJson.JsonML.serialize(["alice", "bob"])
      {:ok, "<alice>bob</alice>"}

      iex> XmlJson.JsonML.serialize(["alice", %{"xmlns" => "https://default.example.com"}, "bob"], exclude_namespaces: true)
      {:ok, "<alice>bob</alice>"}

      iex> XmlJson.JsonML.serialize(["alice", %{"xmlns" => "https://default.example.com"}, "bob"])
      {:ok, "<alice xmlns=\\"https://default.example.com\\">bob</alice>"}

  """
  @spec serialize(list(), json_ml_options()) :: {:ok, binary()} | {:error, term()}
  def serialize(object, opts \\ [])
  def serialize(object, opts), do: Serializer.serialize(object, merge_default_options(opts))

  @spec serialize!(list(), json_ml_options()) :: binary()
  def serialize!(list, opts \\ [])

  def serialize!(list, opts) do
    case serialize(list, opts) do
      {:ok, xml} -> xml
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Deserializes the given XML string.

  Returns an `:ok` tuple with the XML deserialized to a List

  ## Examples

      iex> XmlJson.JsonML.deserialize("<alice>bob</alice>")
      {:ok, ["alice", "bob"]}

      iex> XmlJson.JsonML.deserialize("<alice xmlns=\\"https://default.example.com\\">bob</alice>", exclude_namespaces: true)
      {:ok, ["alice", "bob"]}

      iex> XmlJson.JsonML.deserialize("<alice xmlns=\\"https://default.example.com\\">bob</alice>")
      {:ok, ["alice", %{"xmlns" => "https://default.example.com"}, "bob"]}

  """
  @spec deserialize(binary(), json_ml_options()) :: {:ok, list()} | {:error, term()}
  def deserialize(xml, opts \\ [])
  def deserialize(xml, opts), do: Deserializer.deserialize(xml, merge_default_options(opts))

  @spec deserialize!(binary(), json_ml_options()) :: list()
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
