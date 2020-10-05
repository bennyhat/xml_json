defmodule XmlJson.BadgerFishTest do
  use ExUnit.Case

  doctest XmlJson.BadgerFish

  describe "deserialize" do
    test "element names become object properties" do
      xml = """
      <root><dog><piglet>cat</piglet><doglet>puppy</doglet></dog><horse>fifteen</horse></root>
      """

      assert {:ok,
              %{
                "root" => %{
                  "dog" => %{"piglet" => %{"$" => "cat"}, "doglet" => %{"$" => "puppy"}},
                  "horse" => %{"$" => "fifteen"}
                }
              }} == XmlJson.BadgerFish.deserialize(xml)
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

      assert {:ok, %{"alice" => %{"bob" => %{"$" => "charlie"}, "david" => %{"$" => "edgar"}}}} ==
               XmlJson.BadgerFish.deserialize(xml)
    end

    test "multiple elements at the same level become array elements" do
      xml = """
      <alice><bob>charlie</bob><bob>david</bob></alice>
      """

      assert {:ok, %{"alice" => %{"bob" => [%{"$" => "charlie"}, %{"$" => "david"}]}}} ==
               XmlJson.BadgerFish.deserialize(xml)
    end

    test "attributes go in properties whose names begin with `@`" do
      xml = """
      <alice charlie="david">bob</alice>
      """

      assert {:ok, %{"alice" => %{"$" => "bob", "@charlie" => "david"}}} ==
               XmlJson.BadgerFish.deserialize(xml)
    end

    test "the default namespace URI goes in @xmlns.$" do
      xml = """
      <alice xmlns="http://some-namespace">bob</alice>
      """

      assert {:ok, %{"alice" => %{"$" => "bob", "@xmlns" => %{"$" => "http:\/\/some-namespace"}}}} ==
               XmlJson.BadgerFish.deserialize(xml)
    end

    test "other namespaces go in other properties of @xmlns" do
      xml = """
      <alice xmlns="http:\/\/some-namespace" xmlns:charlie="http:\/\/some-other-namespace">bob</alice>
      """

      assert {:ok,
              %{
                "alice" => %{
                  "$" => "bob",
                  "@xmlns" => %{
                    "$" => "http:\/\/some-namespace",
                    "charlie" => "http:\/\/some-other-namespace"
                  }
                }
              }} == XmlJson.BadgerFish.deserialize(xml)
    end

    test "elements with namespace prefixes become object properties, too" do
      xml = """
      <alice xmlns="http://some-namespace" xmlns:charlie="http://some-other-namespace"> <bob>david</bob> <charlie:edgar>frank</charlie:edgar> </alice>
      """

      result = %{
        "alice" => %{
          "bob" => %{
            "$" => "david",
            "@xmlns" => %{
              "charlie" => "http:\/\/some-other-namespace",
              "$" => "http:\/\/some-namespace"
            }
          },
          "charlie:edgar" => %{
            "$" => "frank",
            "@xmlns" => %{
              "charlie" => "http:\/\/some-other-namespace",
              "$" => "http:\/\/some-namespace"
            }
          },
          "@xmlns" => %{
            "charlie" => "http:\/\/some-other-namespace",
            "$" => "http:\/\/some-namespace"
          }
        }
      }

      assert {:ok, result} == XmlJson.BadgerFish.deserialize(xml)
    end

    test "leading text is preserved" do
      xml = """
      <dog>cat<horse>2</horse></dog>
      """

      assert {:ok,
              %{
                "dog" => %{
                  "$" => "cat",
                  "horse" => %{"$" => 2}
                }
              }} == XmlJson.BadgerFish.deserialize(xml)
    end

    test "trailing text is absorbed" do
      xml = """
      <dog><horse>2</horse>cat</dog>
      """

      assert {:ok,
              %{
                "dog" => %{
                  "horse" => %{"$" => 2}
                }
              }} == XmlJson.BadgerFish.deserialize(xml)
    end
  end

  describe "serialize/1" do
    test "object properties become element names" do
      object = %{
        "root" => %{
          "dog" => %{"piglet" => %{"$" => "cat"}, "doglet" => %{"$" => "puppy"}},
          "horse" => %{"$" => "fifteen"}
        }
      }

      xml = """
      <root><dog><doglet>puppy</doglet><piglet>cat</piglet></dog><horse>fifteen</horse></root>
      """

      assert {:ok, String.trim(xml)} == XmlJson.BadgerFish.serialize(object)
    end

    test "the dollar properties of an element go into the text of an element" do
      object = %{"alice" => %{"$" => "bob"}}
      xml = """
      <alice>bob</alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.BadgerFish.serialize(object)
    end

    test "nested properties become nested elements" do
      object = %{
        "alice" => %{
          "bob" => %{
            "$" => "charlie"
          },
          "david" => %{
            "$" => "edgar"
          }
        }
      }
      xml = """
      <alice><bob>charlie</bob><david>edgar</david></alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.BadgerFish.serialize(object)
    end

    test "properties starting with `@` become attributes" do
      object = %{"alice" => %{"$" => "bob", "@charlie" => "david"}}

      xml = """
      <alice charlie="david">bob</alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.BadgerFish.serialize(object)
    end

    test "the default namespace is applied, if provided" do
      object = %{"alice" => %{"$" => "bob", "@xmlns" => %{"$" => "http:\/\/some-namespace"}}}

      xml = """
      <alice xmlns="http:\/\/some-namespace">bob</alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.BadgerFish.serialize(object)
    end

    test "other namespaces are handled too" do
      object = %{
        "alice" => %{
          "$" => "bob",
          "@xmlns" => %{
            "$" => "http:\/\/some-namespace",
            "charlie" => "http:\/\/some-other-namespace"
          }
        }
      }

      xml = """
      <alice xmlns="http:\/\/some-namespace" xmlns:charlie="http:\/\/some-other-namespace">bob</alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.BadgerFish.serialize(object)
    end

    test "nested applications of xml namespaces are not repeated" do
      object = %{
        "alice" => %{
          "bob" => %{
            "$" => "david",
            "@xmlns" => %{
              "charlie" => "http:\/\/some-other-namespace",
              "$" => "http:\/\/some-namespace"
            }
          },
          "charlie:edgar" => %{
            "$" => "frank",
            "@xmlns" => %{
              "charlie" => "http:\/\/some-other-namespace",
              "$" => "http:\/\/some-namespace",
              "chet" => "http:\/\/namespace.example.com"
            }
          },
          "@xmlns" => %{
            "charlie" => "http:\/\/some-other-namespace",
            "$" => "http:\/\/some-namespace"
          }
        }
      }

      xml = """
      <alice xmlns="http://some-namespace" xmlns:charlie="http://some-other-namespace"><bob>david</bob><charlie:edgar xmlns:chet="http://namespace.example.com">frank</charlie:edgar></alice>
      """

      assert {:ok, String.trim(xml)} == XmlJson.BadgerFish.serialize(object)
    end
  end
end
