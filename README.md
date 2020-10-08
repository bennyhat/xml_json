# XmlJson

[![hex.pm](https://img.shields.io/hexpm/v/xml_json.svg)](https://hex.pm/packages/xml_json)
[![hex.pm](https://img.shields.io/hexpm/dt/xml_json.svg)](https://hex.pm/packages/xml_json)
[![hex.pm](https://img.shields.io/hexpm/l/xml_json.svg)](https://hex.pm/packages/xml_json)
[![github.com](https://img.shields.io/github/last-commit/bennyhat/xml_json.svg)](https://github.com/bennyhat/xml_json)

Should you convert XML to JSON? Probably not.

If you have to though (and have decent control over the providers and consumers
of the XML and JSON), then there are some decent conventions out there for
lossless and near-lossless conversion, such as:

- [`abdera`](http://wiki.open311.org/JSON_and_XML_Conversion/#the-abdera-convention)
- [`badgerfish`](http://www.sklar.com/badgerfish/)
- [`cobra`](http://wiki.open311.org/JSON_and_XML_Conversion/#the-cobra-convention)
- [`gdata`](http://wiki.open311.org/JSON_and_XML_Conversion/#the-gdata-convention)
- [`parker`](https://developer.mozilla.org/en-US/docs/Archive/JXON#The_Parker_Convention) (pretty lossy, but my personal favorite)
- [`yahoo`](https://developer.yahoo.com/yql/guide/response.html#response-xml-to-json) (okay, maybe they're not all great, but they tried)

Presently this only supports Parker and BadgerFish and is largely happy path
testing with the examples provided by each convention. That being said,
eventually this will come up to a `> 0` major version when that is all worked
out.

Otherwise, this does NOT handle massive XML documents with grace, as it
converts to a full JSON/Map object in memory.

A port of the great Python library [`xmljson`](https://pypi.org/project/xmljson/)

## Usage

### Parker
```elixir
iex> XmlJson.Parker.deserialize("<root><dog>cat</dog></root>", preserve_root: true)
{:ok, %{"root" => %{"dog" => "cat"}}}

iex> XmlJson.Parker.serialize(%{"root" => %{"dog" => "cat"}}, preserve_root: "root")
{:ok, "<root><dog>cat</dog></root>"}
```

### BadgerFish
```elixir
iex> XmlJson.BadgerFish.deserialize("<root attr=\"hello\"><dog>cat</dog></root>")
{:ok, %{"root" => %{"@attr" => "hello", "dog" => %{"$" => "cat"}}}}

iex> XmlJson.BadgerFish.serialize(%{"root" => %{"@attr" => "hello", "dog" => %{"$" => "cat"}}})
{:ok, "<root attr=\"hello\"><dog>cat</dog></root>"}
```

## Installation

The package can be installed by adding `xml_json` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:xml_json, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/xml_json](https://hexdocs.pm/xml_json).

## License

[MIT](LICENSE) Copyright (c) 2020 Ben Brewer
