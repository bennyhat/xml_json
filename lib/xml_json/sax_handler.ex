defmodule XmlJson.SaxHandler do
  @moduledoc """
  A generic Sax handler that creates a basic JSON version out of an XML document
  """
  @behaviour Saxy.Handler

  defmodule State do
    defstruct state: [], opts: %{}
  end

  def parse_string(xml, opts \\ %{}) do
    opts = Map.merge(%{try_parse: true}, opts)

    case Saxy.parse_string(xml, __MODULE__, %State{opts: opts, state: []}) do
      {:ok, _} = ok ->
        ok

      {:halt, state, rest} ->
        {:error,
         "Deserialization failed while walking XML. Failed with state of #{inspect(state)} and remaining XML of #{inspect(rest)}"}

      {:error, _} = error ->
        error
    end
  end

  def encode(simple_form) do
    xml = Saxy.encode!(simple_form)
    {:ok, xml}
  rescue
    e ->
      {:error, e}
  end

  def handle_event(:start_document, _prolog, state) do
    {:ok, %State{state | state: [%{attributes: []}]}}
  end

  def handle_event(:end_document, _data, %State{state: [%{children: [root]}]}) do
    {:ok, root}
  end

  def handle_event(:start_element, {name, attributes}, state) do
    [parent | _rest] = state.state
    parent_ns = extract_ns_attributes(parent.attributes)

    current_element = %{
      name: name,
      attributes: attributes ++ parent_ns
    }

    {:ok, %State{state | state: [current_element | state.state]}}
  end

  def handle_event(:end_element, _name, state) do
    [current_element, parent | rest] = state.state

    parent =
      Map.update(parent, :children, [current_element], fn children ->
        children ++ [current_element]
      end)

    {:ok, %State{state | state: [parent | rest]}}
  end

  def handle_event(:characters, chars, state) do
    [current_element | rest] = state.state

    {:ok, %State{state | state: [maybe_add_text(current_element, chars, state.opts) | rest]}}
  end

  defp maybe_add_text(%{children: _} = element, _chars, _opts), do: element

  defp maybe_add_text(element, chars, %{try_parse: true}),
    do: Map.put(element, :text, try_parse(chars))

  defp maybe_add_text(element, chars, %{try_parse: false}),
    do: Map.put(element, :text, String.trim(chars, " "))

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

  defp integer_parse(value) do
    case Integer.parse(value) do
      {parsed, ""} -> parsed
      _ -> :error
    end
  rescue
    _ -> :error
  end

  defp float_parse(value) do
    case Float.parse(value) do
      {parsed, ""} -> parsed
      _ -> :error
    end
  rescue
    _ -> :error
  end

  defp is_ns_attr?({"xmlns", _v}), do: true
  defp is_ns_attr?({"xmlns:" <> _rest, _v}), do: true
  defp is_ns_attr?(_), do: false
end
