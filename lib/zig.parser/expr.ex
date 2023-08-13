defmodule Zig.Parser.Expr do
  def post_traverse(rest, [{:Expr, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  @binaryoperators ~w[or and == != < > <= >= & ^ | orelse << >> <<| + - ++ +% -%
   +| -| || * / % ** *% *|]a

  defp parse([left, op | right]) when op in @binaryoperators do
    {op, left, parse(right)}
  end

  @prefixoperators ~w[! - ~ -% & try await]a

  defp parse([op | rest]) when op in @prefixoperators, do: {op, parse(rest)}

  @expr_tags ~w[comptime nosuspend return resume]a

  for tag <- @expr_tags do
    defp parse([unquote(tag), expr]), do: {unquote(tag), expr}
  end

  defp parse([value, :catch, code]) do
    {:catch, value, code}
  end

  defp parse([value, :catch, :|, payload, :|, code]) do
    {:catch, value, payload, code}
  end

  defp parse([arg]), do: arg

  defp parse([e, {:empty}]) do
    {:empty, e}
  end

  defp parse([e, list]) when is_list(list) do
    {:array, e, list}
  end

  defp parse([e, map]) when is_map(map) do
    {:struct, e, map}
  end

  defp parse_break([]), do: :break

  defp parse_break([:COLON, tag | rest]) do
    case rest do
      [] -> {:break, tag}
      [expr] -> {:break, tag, expr}
    end
  end

  defp parse_continue([]), do: :continue

  defp parse_continue([:COLON, tag]) do
    {:continue, tag}
  end
end
