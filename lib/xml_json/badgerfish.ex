defmodule XmlJson.BadgerFish do
  @moduledoc """
  The BadgerFish implementation of XML <=> JSON

  http://badgerfish.ning.com/
  """

  def deserialize(xml) when is_binary(xml) do
    Saxy.parse_string(xml, XmlJson.BadgerFish.Handler, [])
  end
end

defmodule XmlJson.BadgerFish.Handler do
  @behaviour Saxy.Handler

  def handle_event(:start_document, _prolog, _state) do
    {:ok, [%{attributes: []}]}
  end

  def handle_event(:end_document, _data, [%{children: [root]}]) do
    walked = walk_element(root)

    element = Map.new([{root.name, walked}])
    {:ok, element}
  end

  def handle_event(:start_element, {name, attributes}, state) do
    [parent | _rest] = state
    parent_ns = extract_ns_attributes(parent.attributes)

    current_element = %{
      name: name,
      attributes: attributes ++ parent_ns
    }
    {:ok, [current_element | state]}
  end

  defp extract_ns_attributes(attrs) do
    Enum.filter(attrs, &is_ns_attr?/1)
  end

  defp is_ns_attr?({"xmlns", v}), do: true
  defp is_ns_attr?({"xmlns:" <> _rest, v}), do: true
  defp is_ns_attr?(_), do: false

  def handle_event(:end_element, _name, state) do
    [current_element, parent | rest] = state
    parent = Map.update(parent, :children, [current_element], fn children ->
      children ++ [current_element]
    end)

    {:ok, [parent | rest]}
  end

  def handle_event(:characters, chars, state) do
    [current_element | rest] = state
    current_element = Map.put(current_element, :text, chars)
    {:ok, [current_element | rest]}
  end

  defp walk_element(element) do
    children_or_text = case Map.has_key?(element, :children) do
      false ->
        text = case Map.has_key?(element, :text) do
          true ->
            %{"$" => try_parse(element.text)}
          false -> nil
        end
      true ->
        Enum.reduce(element.children, %{}, fn i, a ->
          walked = walk_element(i)
          Map.update(a, i.name, walked, fn thing ->
            wrapped_thing = List.wrap(thing)
            wrapped_thing ++ [walked]
          end)
        end)
    end

    Enum.reduce(element.attributes, children_or_text, fn {k, v}, a ->
      {k, v} = handle_namespaces(k, v)
      Map.update(a, "@" <> k, v, fn current ->
        Map.merge(current, v)
      end)
    end)
  end

  defp handle_namespaces("xmlns", value) do
    {"xmlns", %{"$" => value}}
  end
  defp handle_namespaces("xmlns:" <> rest, value) do
    {"xmlns", %{rest => value}}
  end
  defp handle_namespaces(key, value), do: {key, value}

  defp try_parse(text) do
    with :error <- integer_parse(text),
         :error <- float_parse(text),
         :error <- boolean_parse(String.downcase(text)) do
      text
    else
      parsed -> parsed
    end
  end

  defp boolean_parse("true"), do: true
  defp boolean_parse("false"), do: false
  defp boolean_parse(_), do: :error

  defp integer_parse(value) do
    case Integer.parse(value) do
      {parsed, ""} -> parsed
      _ -> :error
    end
  end
  defp float_parse(value) do
    case Float.parse(value) do
      {parsed, ""} -> parsed
      _ -> :error
    end
  end
end
