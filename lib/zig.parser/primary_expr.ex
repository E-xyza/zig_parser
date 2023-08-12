for expr_modules <- [
      Zig.Parser.Comptime,
      Zig.Parser.Nosuspend,
      Zig.Parser.Resume,
      Zig.Parser.Return
    ] do
  defmodule expr_modules do
    defstruct [:expr]
  end
end

defmodule Zig.Parser.PrimaryExpr do
  alias Zig.Parser.Break
  alias Zig.Parser.Comptime
  alias Zig.Parser.Continue
  alias Zig.Parser.If
  alias Zig.Parser.Nosuspend
  alias Zig.Parser.Resume
  alias Zig.Parser.Return
  alias Zig.Parser.StructLiteral

  def post_traverse(rest, [{:PrimaryExpr, args} | args_rest], context, _, _) do
    {rest, [parse(args) | args_rest], context}
  end

  defp parse([:comptime | rest]) do
    case parse(rest) do
      result = %{comptime: _} -> %{result | comptime: true}
      expr -> %Comptime{expr: expr}
    end
  end

  defp parse([:if | rest]) do
    If.parse(rest)
  end

  defp parse([:break | rest]) do
    Break.parse(rest)
  end

  defp parse([:continue | rest]) do
    Continue.parse(rest)
  end

  @exprs %{
    nosuspend: Nosuspend,
    resume: Resume,
    return: Return
  }

  for {token, module} <- @exprs do
    defp parse([unquote(token), expr]), do: %unquote(module){expr: expr}
    defp parse([unquote(token)]), do: %unquote(module){}
  end

  defp parse([identifier, map]) when is_map(map) do
    %StructLiteral{type: identifier, values: map}
  end

  defp parse([identifier, list]) when is_list(list) do
    array = list
    |> Enum.with_index
    |> Map.new(fn {item, index} -> {index, item} end)

    %StructLiteral{type: identifier, values: array}
  end

  defp parse([arg]), do: arg
end
