defmodule Zig.Parser.Expr do
  alias Zig.Parser
  alias Zig.Parser.Control

  def post_traverse(rest, [{:Expr, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  # @binaryoperators ~w(or and == != < > <= >= & ^ | orelse << >> + - ++ +% -% || * / % ** *%)a
  #
  # defp parse([left, op | right]) when op in @binaryoperators do
  #  {op, %OperatorOptions{}, [left, parse(right)]}
  # end

  @prefixoperators ~w(! - ~ -% & try await)a

  #  defp parse([op | rest]) when op in @prefixoperators, do: {op, %OperatorOptions{}, parse(rest)}

  defp parse([:if | rest]), do: Control.parse_if(rest)
  defp parse([:break | rest]), do: parse_break(rest)
  defp parse([:continue | rest]), do: parse_continue(rest)

  @expr_tags ~w(comptime nosuspend return resume)a

  for tag <- @expr_tags do
    defp parse([unquote(tag), expr]), do: {unquote(tag), expr}
  end

  defp parse([:for | rest]), do: Control.parse_for(rest)

  defp parse([:inline, :for | rest]) do
    rest
    |> Control.parse_for()
    |> Parser.put_opt(:inline, true)
  end

  defp parse([:while | rest]), do: Control.parse_while(rest)

  defp parse([:inline, :while | rest]) do
    rest
    |> Control.parse_while()
    |> Parser.put_opt(:inline, true)
  end

  defp parse([label, :COLON | rest]) do
    rest
    |> parse()
    |> Parser.put_opt(:label, label)
  end

  # consider emplacement of information in the catch block.
  defp parse([value, :catch, :|, payload, :|, code]) do
    {:catch, %{}, [value, code, payload: payload]}
  end

  defp parse([value, :catch, code]) do
    {:catch, %{}, [value, code]}
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
