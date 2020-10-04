defmodule XmlJson.ParkerTest do
  use ExUnit.Case

  describe "deserialize" do
    test "scalar is absorbed" do
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

    test "mixed mode text, comment and element nodes, absorb text and comments" do
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
end
