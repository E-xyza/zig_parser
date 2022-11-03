defmodule Zig.Parser.VarOptions do
  defstruct [:comment, :align, :linksection, :position, extern: false, export: false, pub: false, threadlocal: false, comptime: false]
end

defmodule Zig.Parser.Var do
  alias Zig.Parser.VarOptions

  def from_args([name | rest]) do
    {opts, type, value} = parse(rest)
    {:var, opts, {name, type, value}}
  end

  defp parse([:COLON, type | rest]) do
    {opts, _, value} = parse(rest)
    {opts, type, value}
  end

  defp parse([:=, value | rest]) do
    {opts, type, _} = parse(rest)
    {opts, type, value}
  end

  defp parse([:linksection, :LPAREN, section, :RPAREN | rest]) do
    {opts, type, value} = parse(rest)
    {%{opts | linksection: section}, type, value}
  end

  defp parse([:align, :LPAREN, align, :RPAREN | rest]) do
    {opts, type, value} = parse(rest)
    {%{opts | align: align}, type, value}
  end

  defp parse([:SEMICOLON]), do: {%VarOptions{}, nil, nil}
end
