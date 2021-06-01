defmodule XmlJson.MixProject do
  use Mix.Project

  @source_url "https://github.com/bennyhat/xml_json"

  def project do
    [
      app: :xml_json,
      version: "0.4.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package(),
      name: "XmlJson",
      source_url: @source_url,
      dialyzer: [plt_file: {:no_warn, ".dialyzer/#{System.version()}.plt"}]
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
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:placebo, "~> 1.2", only: [:dev, :test]}
    ]
  end

  defp description do
    "Convention based conversion to/from XML/JSON"
  end

  defp docs() do
    [
      main: "readme",
      canonical: "http://hexdocs.pm/xml_json",
      source_url: @source_url,
      source_url_pattern: "#{@source_url}/xml_json/blob/master/%{path}#L%{line}",
      extras: ["README.md", "LICENSE"]
    ]
  end

  defp package do
    [
      maintainers: ["bennyhat"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
