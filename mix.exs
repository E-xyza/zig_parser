defmodule ZigParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :zig_parser,
      version: "0.2.0",
      elixir: "~> 1.13",
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
        github: "https://github.com/E-xyza/zig_parser"
      }
    ]
  end

  defp deps do
    [
      {:pegasus, "~> 0.2.3", runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
