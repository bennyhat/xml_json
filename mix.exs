defmodule XmlJson.MixProject do
  use Mix.Project

  def project do
    [
      app: :xml_json,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "XmlJson",
      source_url: "https://github.com/bennyhat/xml_json"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:saxy, "~> 1.2"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Convention based conversion to/from XML/JSON"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bennyhat/xml_json"}
    ]
  end
end
