defmodule Zig.Parser.ConstOptions do
  defstruct [:position, :comment, pub: false, comptime: false]
end

defmodule Zig.Parser.Const do
  alias Zig.Parser.ConstOptions

  def from_args([name | rest]) do
    {opts, type, value} = parse(rest)
    {:const, opts, {name, type, value}}
  end

  defp parse([:COLON, type | rest]) do
    {opts, _, value} = parse(rest)
    {opts, type, value}
  end

  defp parse([:=, value | rest]) do
    {opts, type, _} = parse(rest)
    {opts, type, value}
  end

  defp parse([:SEMICOLON]), do: {%ConstOptions{}, nil, nil}
end
