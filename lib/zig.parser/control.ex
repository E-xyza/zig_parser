defmodule Zig.Parser.Control do
  @moduledoc false

  # control flow parsers:  if, for, while, switch

  def parse_for([:LPAREN, expr, :RPAREN | rest], inline? \\ false) do
    parse_for_payload(inline?, expr, rest)
  end

  defp parse_for_payload(inline?, expr, [:|, :*, item | rest]) do
    parse_for_index(inline?, expr, {:ptr, item}, rest)
  end

  defp parse_for_payload(inline?, expr, [:|, item | rest]) do
    parse_for_index(inline?, expr, item, rest)
  end

  defp parse_for_index(inline?, expr, item, [:COMMA, index, :| | rest]) do
    parse_for_body(inline?, expr, {item, index}, rest)
  end

  defp parse_for_index(inline?, expr, item, [:| | rest]) do
    parse_for_body(inline?, expr, item, rest)
  end

  @inline_for %{false: :for, true: :inline_for}

  @stop_loop [[], [:SEMICOLON]]

  defp parse_for_body(inline?, expr, item, [body | stop]) when stop in @stop_loop do
    {@inline_for[inline?], expr, item, body}
  end

  defp parse_for_body(inline?, expr, item, [body, :else, elsebody]) do
    {@inline_for[inline?], expr, item, body, elsebody}
  end

  # for parsing if statements
  def parse_if([:LPAREN, arg, :RPAREN, :|, :*, payload, :|, consequence | rest]) do
    parse_else(arg, {:ptr_payload, payload, consequence}, rest)
  end

  def parse_if([:LPAREN, arg, :RPAREN, :|, payload, :|, consequence | rest]) do
    parse_else(arg, {:payload, payload, consequence}, rest)
  end

  def parse_if([:LPAREN, arg, :RPAREN, consequence | rest]) do
    parse_else(arg, consequence, rest)
  end

  @if_enders [[], [:SEMICOLON]]
  defp parse_else(arg, consequence, tail) when tail in @if_enders do
    {:if, arg, consequence}
  end

  defp parse_else(arg, consequence, [:else, contrast]) do
    {:if, arg, consequence, contrast}
  end

  defp parse_else(arg, consequence, [:else, :|, payload, :|, contrast]) do
    {:if, arg, consequence, {:payload, payload, contrast}}
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
