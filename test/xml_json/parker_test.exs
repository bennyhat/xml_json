defmodule XmlJson.ParkerTest do
  use ExUnit.Case

  describe "deserialize" do
    test "scalars are absorbed" do
      xml = """
      <root>test</root>
      """

      assert {:ok, "test"} == XmlJson.Parker.deserialize(xml)
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
  describe "serialize/1" do
    test "root scalars are treated as lossy" do
      assert {:error, _} = XmlJson.Parker.serialize("dog")
    end

    test "root lists are treated as lossy" do
      assert {:error, _} = XmlJson.Parker.serialize([1, 2, 3])
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
  end
end
