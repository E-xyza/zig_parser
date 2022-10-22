defmodule Zig.Parser.Expr do
  alias Zig.Parser.TypeExpr

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

  defp analyze_args([:if | rest]), do: parse_if(rest)
  defp analyze_args([:break | rest]), do: parse_break(rest)
  defp analyze_args([:continue | rest]), do: parse_continue(rest)

  @expr_tags ~w(comptime nosuspend return resume)a

  for tag <- @expr_tags do
    defp analyze_args([unquote(tag), expr]), do:  {unquote(tag), expr}
  end

  defp analyze_args([:for | rest]), do: parse_for(rest)

  defp analyze_args([:inline, :for | rest]), do: parse_for(rest, true)

  defp analyze_args([:while | rest]), do: parse_while(rest)

  defp analyze_args([:inline, :while | rest]), do: parse_while(rest, true)

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

  defp parse_if([:LPAREN, arg, :RPAREN, :PIPE, :ASTERISK, payload, :PIPE, consequence | rest]) do
    parse_else(arg, {:ptr_payload, payload, consequence}, rest)
  end

  defp parse_if([:LPAREN, arg, :RPAREN, :PIPE, payload, :PIPE, consequence | rest]) do
    parse_else(arg, {:payload, payload, consequence}, rest)
  end

  defp parse_if([:LPAREN, arg, :RPAREN, consequence | rest]) do
    parse_else(arg, consequence, rest)
  end

  defp parse_else(arg, consequence, []) do
    {:if, arg, consequence}
  end

  defp parse_else(arg, consequence, [:else, contrast]) do
    {:if, arg, consequence, contrast}
  end

  defp parse_else(arg, consequence, [:else, :PIPE, payload, :PIPE, contrast]) do
    {:if, arg, consequence, {:payload, payload, contrast}}
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

  defp parse_for([:LPAREN, expr, :RPAREN | rest], inline? \\ false) do
    parse_for_payload(inline?, expr, rest)
  end

  defp parse_for_payload(inline?, expr, [:PIPE, :ASTERISK, item | rest]) do
    parse_for_index(inline?, expr, {:ptr, item}, rest)
  end

  defp parse_for_payload(inline?, expr, [:PIPE, item | rest]) do
    parse_for_index(inline?, expr, item, rest)
  end

  defp parse_for_index(inline?, expr, item, [:COMMA, index, :PIPE | rest]) do
    parse_for_body(inline?, expr, {item, index}, rest)
  end

  defp parse_for_index(inline?, expr, item, [:PIPE | rest]) do
    parse_for_body(inline?, expr, item, rest)
  end

  @inline_for %{false: :for, true: :inline_for}

  defp parse_for_body(inline?, expr, item, [body]) do
    {@inline_for[inline?], expr, item, body}
  end

  defp parse_for_body(inline?, expr, item, [body, :else, elsebody]) do
    {@inline_for[inline?], expr, item, body, elsebody}
  end

  defp parse_while([:LPAREN, condition, :RPAREN | rest], inline? \\ false) do
    parse_while_payload(inline?, condition, rest)
  end

  defp parse_while_payload(inline?, condition, [:PIPE, payload, :PIPE | rest]) do
    parse_while_body(inline?, condition, payload, rest)
  end

  defp parse_while_payload(inline?, condition, [:PIPE, :ASTERISK, payload, :PIPE | rest]) do
    parse_while_continue(inline?, condition, {:ptr, payload}, rest)
  end

  defp parse_while_payload(inline?, condition, rest) do
    parse_while_continue(inline?, condition, nil, rest)
  end

  defp parse_while_continue(inline?, condition, payload, [:COLON, :LPAREN, continue, :RPAREN | rest]) do
    parse_while_body(inline?, {condition, continue}, payload, rest)
  end

  defp parse_while_continue(inline?, condition, payload, rest) do
    parse_while_body(inline?, condition, payload, rest)
  end

  @inline_while %{false: :while, true: :inline_while}

  defp parse_while_body(inline?, condition_and_continue, payload, [body]) do
    {@inline_while[inline?], condition_and_continue, add_payload(body, payload)}
  end

  defp parse_while_body(inline?, condition_and_continue, payload, [body, :else, else_body]) do
    {@inline_while[inline?], condition_and_continue, add_payload(body, payload), else_body}
  end

  defp parse_while_body(inline?, condition_and_continue, payload, [body, :else, :PIPE, else_payload, :PIPE, else_body]) do
    {@inline_while[inline?], condition_and_continue, add_payload(body, payload), add_payload(else_body, else_payload)}
  end


  defp add_payload(body, payload) do
    case payload do
      nil -> body
      {:ptr, payload} when is_binary(payload) -> {:ptr_payload, payload, body}
      payload when is_binary(payload) -> {:payload, payload, body}
    end
  end
end
