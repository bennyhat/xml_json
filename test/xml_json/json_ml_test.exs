defmodule XmlJson.JsonMLTest do
  use ExUnit.Case
  use Placebo

  doctest XmlJson.JsonML

  describe "deserialize" do
    test "returns an error tuple if XML can't be parsed" do
      xml = """
      <roottest</root>
      """

      assert {:error, _} = XmlJson.JsonML.deserialize(xml)
    end

    test "element names become the first list entry" do
      xml = """
      <root><dog><piglet>cat</piglet><doglet>puppy</doglet></dog><horse>fifteen</horse></root>
      """

      assert {:ok,
              [
                "root",
                ["dog", ["piglet", "cat"], ["doglet", "puppy"]],
                ["horse", "fifteen"]
              ]} == XmlJson.JsonML.deserialize(xml)
    end

    test "text content of elements goes in the last list entry" do
      xml = """
      <alice>bob</alice>
      """

      assert {:ok, ["alice", "bob"]} == XmlJson.JsonML.deserialize(xml)
    end

    test "nested elements become intermediate lists" do
      xml = """
      <alice><bob>charlie</bob><david>edgar</david></alice>
      """

      assert {:ok, ["alice", ["bob", "charlie"], ["david", "edgar"]]} ==
               XmlJson.JsonML.deserialize(xml)
    end

    test "multiple elements at the same level become intermediate lists" do
      xml = """
      <alice><bob>charlie</bob><bob>david</bob></alice>
      """

      assert {:ok, ["alice", ["bob", "charlie"], ["bob", "david"]]} ==
               XmlJson.JsonML.deserialize(xml)
    end

    test "attributes go into a property Map after the first element" do
      xml = """
      <alice charlie="david">bob</alice>
      """

      assert {:ok, ["alice", %{"charlie" => "david"}, "bob"]}
      XmlJson.JsonML.deserialize(xml)
    end

    test "the default namespace URI goes in an xmlns property" do
      xml = """
      <alice xmlns="http://some-namespace">bob</alice>
      """

      assert {:ok, ["alice", %{"xmlns" => "http:\/\/some-namespace"}, "bob"]} ==
               XmlJson.JsonML.deserialize(xml)
    end

    test "other namespaces go in other properties of @xmlns" do
      xml = """
      <alice xmlns="http:\/\/some-namespace" xmlns:charlie="http:\/\/some-other-namespace">bob</alice>
      """

      assert {:ok,
              [
                "alice",
                %{
                  "xmlns" => "http:\/\/some-namespace",
                  "xmlns:charlie" => "http:\/\/some-other-namespace"
                },
                "bob"
              ]} == XmlJson.JsonML.deserialize(xml)
    end

    test "elements with namespace prefixes don't include top level NS stuff" do
      xml = """
      <alice xmlns="http://some-namespace" xmlns:charlie="http://some-other-namespace"> <bob>david</bob> <charlie:edgar>frank</charlie:edgar> </alice>
      """

      result = [
        "alice",
        %{
          "xmlns" => "http:\/\/some-namespace",
          "xmlns:charlie" => "http:\/\/some-other-namespace"
        },
        [
          "bob",
          "david"
        ],
        [
          "charlie:edgar",
          "frank"
        ]
      ]

      assert {:ok, result} == XmlJson.JsonML.deserialize(xml)
    end

    test "leading text is preserved" do
      xml = """
      <dog>cat<horse>2</horse></dog>
      """

      assert {:ok,
              [
                "dog",
                "cat",
                ["horse", 2]
              ]} == XmlJson.JsonML.deserialize(xml)
    end

    test "trailing text is preserved" do
      xml = """
      <dog><horse>2</horse>cat</dog>
      """

      assert {:ok,
              [
                "dog",
                ["horse", 2],
                "cat"
              ]} == XmlJson.JsonML.deserialize(xml)
    end

    test "newlines that are alone are absorbed" do
      xml = """
      <dog>
      </dog>
      """

      assert {:ok, ["dog"]} == XmlJson.JsonML.deserialize(xml)
    end

    test "namespaces can be excluded through an option" do
      xml = """
      <alice xmlns="http://some-namespace" xmlns:charlie="http://some-other-namespace"> <bob>david</bob> <charlie:edgar>frank</charlie:edgar> </alice>
      """

      result = [
        "alice",
        ["bob", "david"],
        ["charlie:edgar", "frank"]
      ]

      assert {:ok, result} == XmlJson.JsonML.deserialize(xml, exclude_namespaces: true)
    end
  end

  describe "deserialize!/2" do
    test "raises an error when XML can't be parsed" do
      xml = """
      <roottest</root>
      """

      assert_raise(Saxy.ParseError, fn ->
        XmlJson.JsonML.deserialize!(xml)
      end)
    end
  end

  describe "serialize/1" do
    test "returns an error when XML cannot be formed" do
      allow Saxy.encode!(any()), exec: fn _ -> raise "something unexpected" end

      assert {:error, _} = XmlJson.JsonML.serialize(["dog", "cat"])
    end

    test "intermediate lists become element names" do
      object = [
        "root",
        ["dog", ["piglet", "cat"], ["doglet", "puppy"]],
        ["horse", "fifteen"]
      ]

      xml = """
      <root><dog><piglet>cat</piglet><doglet>puppy</doglet></dog><horse>fifteen</horse></root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.JsonML.serialize(object)
    end

    test "non-intermediate lists become element text" do
      object = ["alice", "bob"]

      xml = """
      <alice>bob</alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.JsonML.serialize(object)
    end

    test "nested lists become nested elements" do
      object = [
        "alice",
        ["bob", "charlie"],
        ["david", "edgar"]
      ]

      xml = """
      <alice><bob>charlie</bob><david>edgar</david></alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.JsonML.serialize(object)
    end

    test "attribute Maps become attributes" do
      object = ["alice", %{"charlie" => "david"}, "bob"]

      xml = """
      <alice charlie="david">bob</alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.JsonML.serialize(object)
    end

    test "the default namespace is applied, if provided" do
      object = ["alice", %{"xmlns" => "http:\/\/some-namespace"}, "bob"]

      xml = """
      <alice xmlns="http:\/\/some-namespace">bob</alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.JsonML.serialize(object)
    end

    test "other namespaces are handled too" do
      object = [
        "alice",
        %{
          "xmlns" => "http:\/\/some-namespace",
          "xmlns:charlie" => "http:\/\/some-other-namespace"
        },
        "bob"
      ]

      xml = """
      <alice xmlns="http:\/\/some-namespace" xmlns:charlie="http:\/\/some-other-namespace">bob</alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.JsonML.serialize(object)
    end

    test "nested applications of xml namespaces are repeated" do
      object = [
        "alice",
        %{
          "xmlns:charlie" => "http:\/\/some-other-namespace",
          "xmlns" => "http:\/\/some-namespace"
        },
        [
          "bob",
          %{
            "xmlns:charlie" => "http:\/\/some-other-namespace",
            "xmlns" => "http:\/\/some-namespace"
          },
          "david"
        ],
        [
          "charlie:edgar",
          %{
            "xmlns:charlie" => "http:\/\/some-other-namespace",
            "xmlns" => "http:\/\/some-namespace",
            "xmlns:chet" => "http:\/\/namespace.example.com"
          },
          "frank"
        ]
      ]

      xml = """
      <alice xmlns="http://some-namespace" xmlns:charlie="http://some-other-namespace"><bob xmlns="http://some-namespace" xmlns:charlie="http://some-other-namespace">david</bob><charlie:edgar xmlns="http://some-namespace" xmlns:charlie="http://some-other-namespace" xmlns:chet="http://namespace.example.com">frank</charlie:edgar></alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.JsonML.serialize(object)
    end

    test "namespaces can be excluded through an option" do
      object = [
        "alice",
        %{
          "xmlns:charlie" => "http:\/\/some-other-namespace",
          "xmlns" => "http:\/\/some-namespace"
        },
        [
          "bob",
          %{
            "xmlns:charlie" => "http:\/\/some-other-namespace",
            "xmlns" => "http:\/\/some-namespace"
          },
          "david"
        ],
        [
          "charlie:edgar",
          %{
            "xmlns:charlie" => "http:\/\/some-other-namespace",
            "xmlns" => "http:\/\/some-namespace",
            "xmlns:chet" => "http:\/\/namespace.example.com"
          },
          "frank"
        ]
      ]

      xml = """
      <alice><bob>david</bob><charlie:edgar>frank</charlie:edgar></alice>
      """

      assert {:ok, String.trim(xml)} ==
               XmlJson.JsonML.serialize(object, exclude_namespaces: true)
    end

    test "leading text is preserved" do
      object = ["dog", "cat", ["horse", 2]]

      xml = """
      <dog>cat<horse>2</horse></dog>
      """

      assert {:ok, String.trim(xml)} == XmlJson.JsonML.serialize(object)
    end

    test "trailing text is preserved" do
      object = ["dog", ["horse", 2], "cat"]

      xml = """
      <dog><horse>2</horse>cat</dog>
      """

      assert {:ok, String.trim(xml)} == XmlJson.JsonML.serialize(object)
    end
  end

  describe "serialize!/2" do
    test "raises an error when XML cannot be formed" do
      error = "something unexpected"
      allow Saxy.encode!(any()), exec: fn _ -> raise error end

      assert_raise(RuntimeError, error, fn ->
        XmlJson.JsonML.serialize!(%{"dog" => "cat"})
      end)
    end
  end
end
