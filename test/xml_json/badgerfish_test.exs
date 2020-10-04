defmodule XmlJson.BadgerFishTest do
  use ExUnit.Case

  describe "deserialize" do
    test "element names become object properties" do
      xml = """
      <root><dog><piglet>cat</piglet><doglet>puppy</doglet></dog><horse>fifteen</horse></root>
      """

      assert {:ok, %{"root" => %{"dog" => %{"piglet" => %{"$" => "cat"}, "doglet" => %{"$" => "puppy"}}, "horse" => %{"$" => "fifteen"}}}} == XmlJson.BadgerFish.deserialize(xml)
    end

    test "text content of elements goes in the $ property of an object" do
      xml = """
      <alice>bob</alice>
      """

      assert {:ok, %{"alice" => %{"$" => "bob"}}} == XmlJson.BadgerFish.deserialize(xml)
    end

    test "nested elements become nested properties" do
      xml = """
      <alice><bob>charlie</bob><david>edgar</david></alice>
      """

      assert {:ok, %{"alice" => %{"bob" => %{"$" => "charlie"}, "david" => %{"$" => "edgar"}}}} == XmlJson.BadgerFish.deserialize(xml)
    end

    test "multiple elements at the same level become array elements" do
      xml = """
      <alice><bob>charlie</bob><bob>david</bob></alice>
      """

      assert {:ok, %{"alice" => %{"bob" => [%{"$" => "charlie"}, %{"$" => "david"}]}}} == XmlJson.BadgerFish.deserialize(xml)
    end

    test "attributes go in properties whose names begin with `@`" do
      xml = """
      <alice charlie="david">bob</alice>
      """

      assert {:ok, %{"alice" => %{"$" => "bob", "@charlie" => "david"}}} == XmlJson.BadgerFish.deserialize(xml)
    end

    test "the default namespace URI goes in @xmlns.$" do
      xml = """
      <alice xmlns="http://some-namespace">bob</alice>
      """

      assert {:ok, %{"alice" => %{"$" => "bob", "@xmlns" => %{"$" => "http:\/\/some-namespace"}}}} == XmlJson.BadgerFish.deserialize(xml)
    end

    test "other namespaces go in other properties of @xmlns" do
      xml = """
      <alice xmlns="http:\/\/some-namespace" xmlns:charlie="http:\/\/some-other-namespace">bob</alice>
      """

      assert {:ok, %{"alice" => %{"$" => "bob", "@xmlns" => %{"$" => "http:\/\/some-namespace", "charlie" => "http:\/\/some-other-namespace"}}}} == XmlJson.BadgerFish.deserialize(xml)
    end

    test "elements with namespace prefixes become object properties, too" do
      xml = """
      <alice xmlns="http://some-namespace" xmlns:charlie="http://some-other-namespace"> <bob>david</bob> <charlie:edgar>frank</charlie:edgar> </alice>
      """

      result = %{ "alice" => %{ "bob" => %{ "$" => "david" , "@xmlns" => %{"charlie" => "http:\/\/some-other-namespace" , "$" => "http:\/\/some-namespace"} } , "charlie:edgar" => %{ "$" => "frank" , "@xmlns" => %{"charlie" => "http:\/\/some-other-namespace", "$" => "http:\/\/some-namespace"} }, "@xmlns" => %{ "charlie" => "http:\/\/some-other-namespace", "$" => "http:\/\/some-namespace"} } }
      assert {:ok, result} == XmlJson.BadgerFish.deserialize(xml)
    end
  end
end
