defmodule XmlJson.ParkerTest do
  use ExUnit.Case
  use Placebo

  doctest XmlJson.Parker

  describe "deserialize/2" do
    test "returns an error tuple if XML can't be parsed" do
      xml = """
      <roottest</root>
      """

      assert {:error, _} = XmlJson.Parker.deserialize(xml)
    end

    test "root is absorbed" do
      xml = """
      <root>test</root>
      """

      assert {:ok, "test"} == XmlJson.Parker.deserialize(xml)
    end

    test "root is optionally preserved" do
      xml = """
      <root>test</root>
      """

      assert {:ok, %{"root" => "test"}} == XmlJson.Parker.deserialize(xml, preserve_root: true)
    end

    test "element names become object properties" do
      xml = """
      <root><name>Xml</name><encoding>ASCII</encoding><cat><name>Moonpie</name><encoding>wildness</encoding></cat></root>
      """

      assert {:ok,
              %{
                "name" => "Xml",
                "encoding" => "ASCII",
                "cat" => %{"encoding" => "wildness", "name" => "Moonpie"}
              }} == XmlJson.Parker.deserialize(xml)
    end

    test "numbers are recognized" do
      xml = """
      <root><age>12</age><height>1.73</height></root>
      """

      assert {:ok, %{"age" => 12, "height" => 1.73}} == XmlJson.Parker.deserialize(xml)
    end

    test "booleans are recognized case insensitive" do
      xml = """
      <root><checked>True</checked><answer>FALSE</answer><poked>true</poked></root>
      """

      assert {:ok, %{"checked" => true, "answer" => false, "poked" => true}} ==
               XmlJson.Parker.deserialize(xml)
    end

    test "strings are escaped" do
      xml = """
      <root>Quote: &quot; New-line:
      </root>
      """

      assert {:ok, "Quote: \" New-line:\n"} == XmlJson.Parker.deserialize(xml)
    end

    test "empty elements become nil" do
      xml = """
      <root><nil/><empty></empty></root>
      """

      assert {:ok, %{"nil" => nil, "empty" => nil}} == XmlJson.Parker.deserialize(xml)
    end

    test "if all siblings have the same name, they become an array" do
      xml = """
      <root><item>1</item><item>2</item><item>three</item></root>
      """

      assert {:ok, [1, 2, "three"]} == XmlJson.Parker.deserialize(xml)
    end

    test "for mixed mode text, comments, attributes and element nodes, it absorb all but the elements" do
      xml = """
      <root version="1.0">testing<!--comment--><element test="true">1</element></root>
      """

      assert {:ok, %{"element" => 1}} == XmlJson.Parker.deserialize(xml)
    end

    test "namespaces get absorbed, and prefixes will just be part of the property name" do
      xml = """
      <root xmlns:ding="http://zanstra.com/ding"><ding:dong>binnen</ding:dong></root>
      """

      assert {:ok, %{"ding:dong" => "binnen"}} == XmlJson.Parker.deserialize(xml)
    end
  end

  describe "deserialize!/2" do
    test "raises an error when XML can't be parsed" do
      xml = """
      <roottest</root>
      """
      assert_raise(Saxy.ParseError, fn ->
        XmlJson.Parker.deserialize!(xml)
      end)
    end
  end

  describe "serialize/2" do
    test "returns an error when XML cannot be formed" do
      allow Saxy.encode!(any()), exec: fn _-> raise "something unexpected" end

      assert {:error, _} = XmlJson.Parker.serialize(false)
    end

    test "root scalars are wrapped in a root element by default" do
      assert {:ok, "<root>dog</root>"} == XmlJson.Parker.serialize("dog")
    end

    test "root lists are joined and wrapped in a root element by default" do
      assert {:ok, "<root>1,2,3</root>"} == XmlJson.Parker.serialize([1, 2, 3])
    end

    test "object properties become (\"sorted\" via Map) element names under a default root" do
      object = %{
        "name" => "Xml",
        "encoding" => "ASCII",
        "cat" => %{"encoding" => "wildness", "name" => "Moonpie"}
      }

      xml = """
      <root><cat><encoding>wildness</encoding><name>Moonpie</name></cat><encoding>ASCII</encoding><name>Xml</name></root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.Parker.serialize(object)
    end

    test "numbers are recognized" do
      object = %{
        "age" => 12,
        "height" => 1.73
      }

      xml = """
      <root><age>12</age><height>1.73</height></root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.Parker.serialize(object)
    end

    test "booleans are recognized" do
      object = %{
        "checked" => true,
        "answer" => false,
        "poked" => true
      }

      xml = """
      <root><answer>false</answer><checked>true</checked><poked>true</poked></root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.Parker.serialize(object)
    end

    test "strings are unescaped" do
      object = %{
        "hello" => "Quote: \" New-line:\n"
      }

      xml = """
      <root><hello>Quote: &quot; New-line:
      </hello></root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.Parker.serialize(object)
    end

    test "nils become empty elements" do
      object = %{
        "dead" => nil
      }

      xml = """
      <root><dead/></root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.Parker.serialize(object)
    end

    test "lists become the same, repeated element" do
      object = %{
        "listy" => [1, 2.3, "four", false]
      }

      xml = """
      <root><listy>1</listy><listy>2.3</listy><listy>four</listy><listy>false</listy></root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.Parker.serialize(object)
    end

    test "can at least put back down namespaced keys" do
      object = %{
        "namespaced:key" => "true"
      }

      xml = """
      <root><namespaced:key>true</namespaced:key></root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.Parker.serialize(object)
    end

    test "root is hoisted, if possible (defaults to \"root\")" do
      object = %{
        "root" => "true",
        "invalid_sibling" => "stuff"
      }

      xml = """
      <root>true</root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.Parker.serialize(object)
    end

    test "root is hoisted, if possible given a custom name" do
      object = %{
        "root" => "true",
        "sibling" => "stuff"
      }

      xml = """
      <sibling>stuff</sibling>
      """

      assert {:ok, String.trim(xml)} == XmlJson.Parker.serialize(object, preserve_root: "sibling")
    end

    test "root is wrapped, if not possible to hoist given a custom name" do
      object = %{
        "root" => "true",
        "sibling" => "stuff"
      }

      xml = """
      <custom><root>true</root><sibling>stuff</sibling></custom>
      """

      assert {:ok, String.trim(xml)} == XmlJson.Parker.serialize(object, preserve_root: "custom")
    end
  end

  describe "serialize!/2" do
    test "raises an error when XML cannot be formed" do
      error = "something unexpected"
      allow Saxy.encode!(any()), exec: fn _-> raise error end

      assert_raise(RuntimeError, error, fn ->
        XmlJson.Parker.serialize!(%{"dog" => "cat"})
      end)
    end
  end
end
