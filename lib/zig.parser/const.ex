defmodule Zig.Parser.ConstOptions do
  defstruct [:position, :doc_comment, pub: false, comptime: false]
end

defmodule Zig.Parser.Const do
  alias Zig.Parser.ConstOptions

  def parse([name | rest]) do
    {opts, type, value} = do_parse(rest)
    {:const, opts, {name, type, value}}
  end

  defp do_parse([:COLON, type | rest]) do
    {opts, _, value} = do_parse(rest)
    {opts, type, value}
  end

  defp do_parse([:=, value | rest]) do
    {opts, type, _} = do_parse(rest)
    {opts, type, value}
  end

  defp do_parse([:SEMICOLON]), do: {%ConstOptions{}, nil, nil}
end
