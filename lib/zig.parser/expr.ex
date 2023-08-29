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

  defp parse([value, :catch, :|, payload, :|, code | rest]) do
    parse([{:catch, value, payload, code} | rest])
  end

  defp parse([value, :catch, code | rest]) do
    parse([{:catch, value, code} | rest])
  end

  defp parse([arg]), do: arg
end
