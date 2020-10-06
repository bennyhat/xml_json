defmodule XmlJson.MixProject do
  use Mix.Project

  def project do
    [
      app: :xml_json,
      version: "0.1.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: docs(),
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

  defp docs() do
    [
      source_url: "https://github.com/bennyhat/xml_json",
      extras: ["README.md"],
      main: "readme",
      source_url_pattern: "https://github.com/bennyhat/xml_json/blob/master/%{path}#L%{line}"
    ]
  end

  defp package do
    [
      maintainers: ["bennyhat"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bennyhat/xml_json"}
    ]
  end
end
