defmodule Zig.Parser.VarOptions do
  defstruct [
    :doc_comment,
    :align,
    :linksection,
    :position,
    extern: false,
    export: false,
    pub: false,
    threadlocal: false,
    comptime: false
  ]
end

defmodule Zig.Parser.Var do
  alias Zig.Parser.VarOptions

  def parse([name | rest]) do
    {opts, type, value} = do_parse(rest)
    {:var, opts, {name, type, value}}
  end

  defp do_parse([:COLON, type | rest]) do
    {opts, _, value} = do_parse(rest)
    {opts, type, value}
  end

  defp do_parse([:=, value | rest]) do
    {opts, type, _} = do_parse(rest)
    {opts, type, value}
  end

  defp do_parse([:linksection, :LPAREN, section, :RPAREN | rest]) do
    {opts, type, value} = do_parse(rest)
    {%{opts | linksection: section}, type, value}
  end

  defp do_parse([:align, :LPAREN, align, :RPAREN | rest]) do
    {opts, type, value} = do_parse(rest)
    {%{opts | align: align}, type, value}
  end

  defp do_parse([:SEMICOLON]), do: {%VarOptions{}, nil, nil}
end
