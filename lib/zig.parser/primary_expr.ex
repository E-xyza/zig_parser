defmodule Zig.Parser.PrimaryExpr do
  alias Zig.Parser.If
  alias Zig.Parser.StructLiteral

  def post_traverse(rest, [{:PrimaryExpr, args} | args_rest], context, _, _) do
    {rest, [parse(args) | args_rest], context}
  end

  defp parse([:comptime | rest]) do
    case parse(rest) do
      result = %{comptime: _} -> %{result | comptime: true}
      expr -> {:comptime, expr}
    end
  end

  defp parse([:if | rest]) do
    If.parse(rest)
  end

  defp parse([:break]), do: :break
  defp parse([:break, :COLON, tag]), do: {:break, tag}
  defp parse([:break, :COLON, tag, expr]), do: {:break, tag, expr}

  defp parse([:continue]), do: :continue
  defp parse([:continue, :COLON, tag]), do: {:continue, tag}

  defp parse([:nosuspend, expr]), do: {:nosuspend, expr}
  defp parse([:resume, expr]), do: {:resume, expr}

  defp parse([:return]), do: :return
  defp parse([:return, expr]), do: {:return, expr}

  defp parse([identifier, map]) when is_map(map) do
    %StructLiteral{type: identifier, values: map}
  end

  defp parse([identifier, list]) when is_list(list) do
    array =
      list
      |> Enum.with_index()
      |> Map.new(fn {item, index} -> {index, item} end)

    %StructLiteral{type: identifier, values: array}
  end

  defp parse([arg]), do: arg
end
