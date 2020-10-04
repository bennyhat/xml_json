defmodule XmlJson.Parker do
  @moduledoc """
  The Parker implementation of XML <=> JSON

  https://developer.mozilla.org/en-US/docs/Archive/JXON#The_Parker_Convention
  """

  def deserialize(xml) when is_binary(xml) do
    {:ok, element} = Saxy.parse_string(xml, XmlJson.SaxHandler, [])
    {:ok, walk_element(element)}
  end

  defp walk_element(element) do
    case Map.has_key?(element, :children) do
      false ->
        case Map.has_key?(element, :text) do
          true -> element.text
          false -> nil
        end

      true ->
        walky =
          Enum.reduce(element.children, %{}, fn i, a ->
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

          _ ->
            walky
        end
    end
  end
end
