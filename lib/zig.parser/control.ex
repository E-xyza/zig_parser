defmodule Zig.Parser.IfOptions do
  defstruct [:position]
end

defmodule Zig.Parser.ForOptions do
  defstruct [:position, inline: false]
end

defmodule Zig.Parser.Control do
  @moduledoc false
  alias Zig.Parser.IfOptions
  alias Zig.Parser.ForOptions

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

  @stop_loop [[], [:SEMICOLON]]

  defp parse_for_code([body | stop], parts) when stop in @stop_loop do
    {:for, %ForOptions{}, Keyword.merge(parts, code: body)}
  end

  defp parse_for_code([body, :else, elsebody], parts) do
    {:for, %ForOptions{}, Keyword.merge(parts, code: body, else: elsebody)}
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

  @if_enders [[], [:SEMICOLON]]
  defp parse_else(tail, parts) when tail in @if_enders do
    {:if, %IfOptions{}, parts}
  end

  defp parse_else([:else, :|, payload, :|, contrast], parts) do
    {:if, %IfOptions{}, Keyword.merge(parts, else: contrast, else_payload: payload)}
  end

  defp parse_else([:else, contrast | _], parts) do
    {:if, %IfOptions{}, Keyword.merge(parts, else: contrast)}
  end

  # while loop parsing
  def parse_while([:LPAREN, condition, :RPAREN | rest], inline? \\ false) do
    parse_while_payload(inline?, condition, rest)
  end

  defp parse_while_payload(inline?, condition, [:|, payload, :| | rest]) do
    parse_while_body(inline?, condition, payload, rest)
  end

  defp parse_while_payload(inline?, condition, [:|, :*, payload, :| | rest]) do
    parse_while_continue(inline?, condition, {:ptr, payload}, rest)
  end

  defp parse_while_payload(inline?, condition, rest) do
    parse_while_continue(inline?, condition, nil, rest)
  end

  defp parse_while_continue(inline?, condition, payload, [
         :COLON,
         :LPAREN,
         continue,
         :RPAREN | rest
       ]) do
    parse_while_body(inline?, {condition, continue}, payload, rest)
  end

  defp parse_while_continue(inline?, condition, payload, rest) do
    parse_while_body(inline?, condition, payload, rest)
  end

  @inline_while %{false: :while, true: :inline_while}

  defp parse_while_body(inline?, condition_and_continue, payload, [body | stop])
       when stop in @stop_loop do
    {@inline_while[inline?], condition_and_continue, add_payload(body, payload)}
  end

  defp parse_while_body(inline?, condition_and_continue, payload, [body, :else, else_body]) do
    {@inline_while[inline?], condition_and_continue, add_payload(body, payload), else_body}
  end

  defp parse_while_body(inline?, condition_and_continue, payload, [
         body,
         :else,
         :|,
         else_payload,
         :|,
         else_body
       ]) do
    {@inline_while[inline?], condition_and_continue, add_payload(body, payload),
     add_payload(else_body, else_payload)}
  end

  defp add_payload(body, payload) do
    case payload do
      nil -> body
      {:ptr, payload} when is_atom(payload) -> {:ptr_payload, payload, body}
      payload when is_atom(payload) -> {:payload, payload, body}
    end
  end

  def parse_switch([:LPAREN, expr, :RPAREN, :LBRACE | rest]) do
    {:switch, expr, parse_switch_prongs(rest, [])}
  end

  defp parse_switch_prongs([expr, :"=>", expr2 | rest], so_far) do
    parse_switch_prongs(rest, [{expr, expr2} | so_far])
  end

  defp parse_switch_prongs([:COMMA | rest], so_far), do: parse_switch_prongs(rest, so_far)

  defp parse_switch_prongs([:RBRACE], so_far), do: Enum.reverse(so_far)
end
