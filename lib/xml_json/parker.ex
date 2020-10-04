defmodule XmlJson.Parker do
  @moduledoc """
  The Parker implementation of XML <=> JSON

  https://developer.mozilla.org/en-US/docs/Archive/JXON#The_Parker_Convention
  """

  def deserialize(xml) when is_binary(xml) do
    Saxy.parse_string(xml, XmlJson.Parker.Handler, [])
  end
end

defmodule XmlJson.Parker.Handler do
  @behaviour Saxy.Handler

  def handle_event(:start_document, _prolog, _state) do
    {:ok, [%{}]}
  end

  def handle_event(:end_document, _data, [%{children: [root]}]) do
    walked = walk_element(root)
    {:ok, walked}
  end

  def handle_event(:start_element, {name, attributes}, state) do
    current_element = %{
      name: name,
      attributes: attributes
    }
    {:ok, [current_element | state]}
  end

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
    case Map.has_key?(element, :children) do
      false -> case Map.has_key?(element, :text) do
        true -> try_parse(element.text)
        false -> nil
      end
      true ->
        walky = Enum.reduce(element.children, %{}, fn i, a ->
          walked = walk_element(i)
          Map.update(a, i.name, walked, fn thing ->
            wrapped_thing = List.wrap(thing)
            wrapped_thing ++ [walked]
          end)
        end)
        case length(Map.keys(walky)) do
          1 ->
            case Map.values(walky) do
              [list] when is_list(list) -> list
              _ -> walky
            end
          _ -> walky
        end
    end
  end

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
