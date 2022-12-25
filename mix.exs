defmodule ZigParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :zig_parser,
      version: "0.1.5",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: "a zig parser in elixir",
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        github: "https://github.com/ityonemo/zig_parser"
      }
    ]
  end

  defp deps do
    [
      {:pegasus, "~> 0.2.2", runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
