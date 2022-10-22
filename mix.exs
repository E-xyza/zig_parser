defmodule ZigParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :zig_parser,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:pegasus, "~> 0.2.2", runtime: false}
    ]
  end
end
