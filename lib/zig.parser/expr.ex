defmodule Zig.Parser.Expr do
  alias Zig.Parser.TypeExpr
  alias Zig.Parser.Control

  def post_traverse(rest, [{__MODULE__, args} | rest_args], context, _, _) do
    {rest, [analyze_args(args) | rest_args], context}
  end

  @binaryoperators %{
    or: :or,
    and: :and,
    EQUALEQUAL: :==,
    EXCLAMATIONMARKEQUAL: :!=,
    LARROW: :<,
    RARROW: :>,
    LARROWEQUAL: :<=,
    RARROWEQUAL: :>=,
    AMPERSAND: :&,
    CARET: :^,
    PIPE: :|,
    orelse: :orelse,
    LARROW2: :"<<",
    RARROW2: :">>",
    PLUS: :+,
    MINUS: :-,
    PLUS2: :++,
    PLUSPERCENT: :"+%",
    MINUSPERCENT: :"-%",
    PIPE2: :||,
    ASTERISK: :*,
    SLASH: :/,
    PERCENT: :%,
    ASTERISK2: :**,
    ASTERISKPERCENT: :"*%"
  }

  for {opname, atom} <- @binaryoperators do
    defp analyze_args([a, unquote(opname) | rest]), do: {unquote(atom), a, analyze_args(rest)}
  end

  @prefixoperators %{
    EXCLAMATIONMARK: :!,
    MINUS: :-,
    TILDE: :"~",
    MINUSPERCENT: :"-%",
    AMPERSAND: :&,
    try: :try,
    await: :await
  }

  for {opname, atom} <- @prefixoperators do
    defp analyze_args([unquote(opname) | rest]), do: {unquote(atom), analyze_args(rest)}
  end

  defp analyze_args([:if | rest]), do: Control.parse_if(rest)
  defp analyze_args([:break | rest]), do: parse_break(rest)
  defp analyze_args([:continue | rest]), do: parse_continue(rest)

  @expr_tags ~w(comptime nosuspend return resume)a

  for tag <- @expr_tags do
    defp analyze_args([unquote(tag), expr]), do: {unquote(tag), expr}
  end

  defp analyze_args([:for | rest]), do: Control.parse_for(rest)

  defp analyze_args([:inline, :for | rest]), do: Control.parse_for(rest, true)

  defp analyze_args([:while | rest]), do: Control.parse_while(rest)

  defp analyze_args([:inline, :while | rest]), do: Control.parse_while(rest, true)

  defp analyze_args([arg]), do: arg

  defp analyze_args([e = %TypeExpr{}, :empty]) do
    {:empty, e}
  end

  defp analyze_args([e = %TypeExpr{}, list]) when is_list(list) do
    {:array, e, list}
  end

  defp analyze_args([e = %TypeExpr{}, map]) when is_map(map) do
    {:struct, e, map}
  end

  defp parse_break([]), do: :break

  defp parse_break([:COLON, identifier | rest]) do
    tag = String.to_atom(identifier)

    case rest do
      [] -> {:break, tag}
      [expr] -> {:break, tag, expr}
    end
  end

  defp parse_continue([]), do: :continue

  defp parse_continue([:COLON, identifier]) do
    {:continue, String.to_atom(identifier)}
  end
end
