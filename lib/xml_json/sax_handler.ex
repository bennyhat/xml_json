defmodule XmlJson.SaxHandler do
  @moduledoc """
  A generic Sax handler that creates a basic JSON version out of an XML document
  """
  @behaviour Saxy.Handler

  def handle_event(:start_document, _prolog, _state) do
    {:ok, [%{attributes: []}]}
  end

  def handle_event(:end_document, _data, [%{children: [root]}]) do
    {:ok, root}
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

  def handle_event(:end_element, _name, state) do
    [current_element, parent | rest] = state

    parent =
      Map.update(parent, :children, [current_element], fn children ->
        children ++ [current_element]
      end)

    {:ok, [parent | rest]}
  end

  def handle_event(:characters, chars, state) do
    [current_element | rest] = state

    {:ok, [maybe_add_text(current_element, chars) | rest]}
  end

  defp maybe_add_text(%{children: _} = element, _chars), do: element
  defp maybe_add_text(element, chars), do: Map.put(element, :text, try_parse(chars))

  defp extract_ns_attributes(attrs) do
    Enum.filter(attrs, &is_ns_attr?/1)
  end

  defp try_parse(text) do
    with :error <- integer_parse(text),
         :error <- float_parse(text),
         :error <- boolean_parse(String.downcase(text)) do
      String.trim(text, " ")
    else
      parsed -> parsed
    end
  end

  defp boolean_parse("true"), do: true
  defp boolean_parse("false"), do: false
  defp boolean_parse(_), do: :error

  defp is_ns_attr?({"xmlns", _v}), do: true
  defp is_ns_attr?({"xmlns:" <> _rest, _v}), do: true
  defp is_ns_attr?(_), do: false

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
