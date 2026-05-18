defmodule Zig.Parser.Statement do
  alias Zig.Parser.Block
  alias Zig.Parser.If
  alias Zig.Parser.Switch

  # BlockStatement: wraps Statement, defer, errdefer, VarAssignStatement
  def post_traverse(rest, [{:BlockStatement, args} | rest_args], context, _, _) do
    {rest, [parse_block_statement(args) | rest_args], context}
  end

  # ExprStatement: if, labeled statements, nosuspend, comptime block
  def post_traverse(rest, [{:ExprStatement, args} | rest_args], context, _, _) do
    {rest, [parse_expr_statement(args) | rest_args], context}
  end

  # Statement: ExprStatement, suspend, or simple assignment
  def post_traverse(rest, [{:Statement, args} | rest_args], context, _, _) do
    {rest, [parse_statement(args) | rest_args], context}
  end

  # BlockStatement parsing
  defp parse_block_statement([:defer | rest_args]) do
    {:defer, parse_block_expr_statement(rest_args)}
  end

  defp parse_block_statement([:errdefer, :|, capture, :| | rest_args]) do
    {:errdefer, capture, parse_block_expr_statement(rest_args)}
  end

  defp parse_block_statement([:errdefer | rest_args]) do
    {:errdefer, parse_block_expr_statement(rest_args)}
  end

  defp parse_block_statement([:comptime | rest_args]) do
    case parse_block_statement(rest_args) do
      %{comptime: _} = parsed -> %{parsed | comptime: true}
      parsed -> {:comptime, parsed}
    end
  end

  defp parse_block_statement([content]), do: content

  # BlockExprStatement parsing (shared helper)
  defp parse_block_expr_statement([%Block{} = block]), do: block
  defp parse_block_expr_statement([statement, :SEMICOLON]), do: statement
  defp parse_block_expr_statement([content]), do: content

  # ExprStatement parsing
  defp parse_expr_statement([:nosuspend | rest_args]) do
    case parse_block_expr_statement(rest_args) do
      %Block{} = block -> %{block | nosuspend: true}
      other -> {:nosuspend, other}
    end
  end

  defp parse_expr_statement([:comptime | rest_args]) do
    case parse_expr_statement(rest_args) do
      %Block{} = block -> %{block | comptime: true}
      other -> {:comptime, other}
    end
  end

  defp parse_expr_statement([:if | rest_args]) do
    If.parse(rest_args)
  end

  defp parse_expr_statement([label, :COLON, :switch | rest]) do
    %{Switch.parse(rest) | label: label}
  end

  defp parse_expr_statement([label, :COLON, statement]) do
    %{statement | label: label}
  end

  # Unlabeled switch expression
  defp parse_expr_statement([:switch | rest]) do
    Switch.parse(rest)
  end

  defp parse_expr_statement([content]), do: content

  # Statement parsing
  defp parse_statement([:suspend | rest_args]) do
    case parse_block_expr_statement(rest_args) do
      %Block{} = block -> %{block | suspend: true}
      other -> {:suspend, other}
    end
  end

  defp parse_statement([:comptime | rest_args]) do
    case parse_statement(rest_args) do
      %{comptime: _} = parsed -> %{parsed | comptime: true}
      parsed -> {:comptime, parsed}
    end
  end

  defp parse_statement([statement, :SEMICOLON]), do: statement

  defp parse_statement([content]), do: content
end
