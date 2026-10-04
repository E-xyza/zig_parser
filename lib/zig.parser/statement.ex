defmodule Zig.Parser.Statement do
  alias Zig.Parser.Block
  alias Zig.Parser.If
  alias Zig.Parser.Switch

  # BlockStatement: wraps Statement, defer, errdefer, VarAssignStatement
  def post_traverse(rest, [{:BlockStatement, args} | rest_args], context, _, _) do
    {rest, [parse_block_statement(args) | rest_args], context}
  end

  # Statement: in zig 0.17 the old ExprStatement rule was folded into Statement,
  # so this one clause covers both: the expression forms (if, labeled statements,
  # nosuspend, comptime block) and suspend / simple assignment.
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

  # the expression-statement forms, folded in from the old ExprStatement rule
  defp parse_statement([:nosuspend | _] = args), do: parse_expr_statement(args)
  defp parse_statement([:if | _] = args), do: parse_expr_statement(args)
  defp parse_statement([:switch | _] = args), do: parse_expr_statement(args)
  defp parse_statement([_, :COLON | _] = args), do: parse_expr_statement(args)

  defp parse_statement([content]), do: content
end
