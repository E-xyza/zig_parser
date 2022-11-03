defmodule Zig.Parser.IfOptions do
  defstruct [:position]
end

defmodule Zig.Parser.ForOptions do
  defstruct [:position, :label, inline: false]
end

defmodule Zig.Parser.WhileOptions do
  defstruct [:position, :label, inline: false]
end

defmodule Zig.Parser.SwitchOptions do
  defstruct [:position, :label, comptime: false]
end

defmodule Zig.Parser.Control do
  @moduledoc false
  alias Zig.Parser.IfOptions
  alias Zig.Parser.ForOptions
  alias Zig.Parser.SwitchOptions
  alias Zig.Parser.WhileOptions

  # control flow parsers:  if, for, while, switch

  def parse_for([:LPAREN, expr, :RPAREN | rest]) do
    parse_for_payload(rest, enum: expr)
  end

  defp parse_for_payload([:|, :*, payload | rest], parts) do
    parse_for_index(rest, Keyword.merge(parts, ptr_payload: payload))
  end

  defp parse_for_payload([:|, payload | rest], parts) do
    parse_for_index(rest, Keyword.merge(parts, payload: payload))
  end

  defp parse_for_index([:COMMA, index, :| | rest], parts) do
    parse_for_code(rest, Keyword.merge(parts, index: index))
  end

  defp parse_for_index([:| | rest], parts) do
    parse_for_code(rest, parts)
  end

  @stop [[], [:SEMICOLON]]

  defp parse_for_code([body | stop], parts) when stop in @stop do
    {:for, %ForOptions{}, Keyword.merge(parts, do: body)}
  end

  defp parse_for_code([body, :else, elsebody], parts) do
    {:for, %ForOptions{}, Keyword.merge(parts, do: body, else: elsebody)}
  end

  # for parsing if statements
  def parse_if([:LPAREN, condition, :RPAREN, :|, :*, payload, :|, consequence | rest]) do
    parse_else(rest, condition: condition, ptr_payload: payload, consequence: consequence)
  end

  def parse_if([:LPAREN, condition, :RPAREN, :|, payload, :|, consequence | rest]) do
    parse_else(rest, condition: condition, payload: payload, consequence: consequence)
  end

  def parse_if([:LPAREN, condition, :RPAREN, consequence | rest]) do
    parse_else(rest, condition: condition, consequence: consequence)
  end

  defp parse_else(tail, parts) when tail in @stop do
    {:if, %IfOptions{}, parts}
  end

  defp parse_else([:else, :|, payload, :|, contrast], parts) do
    {:if, %IfOptions{}, Keyword.merge(parts, else_payload: payload, else: contrast)}
  end

  defp parse_else([:else, contrast | _], parts) do
    {:if, %IfOptions{}, Keyword.merge(parts, else: contrast)}
  end

  # while loop parsing
  def parse_while([:LPAREN, condition, :RPAREN | rest]) do
    parse_while_payload(rest, condition: condition)
  end

  defp parse_while_payload([:|, payload, :| | rest], parts) do
    parse_while_continue(rest, Keyword.merge(parts, payload: payload))
  end

  defp parse_while_payload([:|, :*, payload, :| | rest], parts) do
    parse_while_continue(rest, Keyword.merge(parts, ptr_payload: payload))
  end

  defp parse_while_payload(rest, parts) do
    parse_while_continue(rest, parts)
  end

  defp parse_while_continue([:LPAREN, continue, :RPAREN | rest], parts) do
    parse_while_body(rest, Keyword.merge(parts, continue: continue))
  end

  defp parse_while_continue(rest, parts) do
    parse_while_body(rest, parts)
  end

  defp parse_while_body([:COLON, :LPAREN, next, :RPAREN | rest], parts) do
    parse_while_body(rest, Keyword.merge(parts, next: next))
  end

  defp parse_while_body([body | stop], parts) when stop in @stop do
    {:while, %WhileOptions{}, Keyword.merge(parts, do: body)}
  end

  defp parse_while_body([body, :else, else_body], parts) do
    {:while, %WhileOptions{}, Keyword.merge(parts, do: body, else: else_body)}
  end

  defp parse_while_body([body, :else, :|, else_payload, :|, else_body], parts) do
    {:while, %WhileOptions{},
     Keyword.merge(parts, do: body, else_payload: else_payload, else: else_body)}
  end

  def parse_switch([:LPAREN, condition, :RPAREN, :LBRACE | rest]) do
    {:switch, %SwitchOptions{},
     Keyword.merge([condition: condition], parse_switch_prongs(rest, []))}
  end

  defp parse_switch_prongs([expr, :"=>", expr2 | rest], so_far) do
    parse_switch_prongs(rest, [{expr, expr2} | so_far])
  end

  defp parse_switch_prongs([:COMMA | rest], so_far), do: parse_switch_prongs(rest, so_far)

  defp parse_switch_prongs([:RBRACE], so_far), do: [switches: Enum.reverse(so_far)]
end
