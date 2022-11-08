defmodule Zig.Parser.TypeExpr do
  @literals Zig.Parser.Collected.literals()

  def post_traverse(rest, [{__MODULE__, [literalterm = {literal, _}]} | rest_args], context, _, _)
      when literal in @literals do
    {rest, [literalterm | rest_args], context}
  end

  def post_traverse(rest, [{__MODULE__, [:DOT, enum]} | rest_args], context, _, _) do
    {rest, [{:enumliteral, enum} | rest_args], context}
  end

  def post_traverse(rest, [{__MODULE__, [expr]} | rest_args], context, _, _) do
    {rest, [expr | rest_args], context}
  end

  def post_traverse(rest, [{__MODULE__, ref} | rest_args], context, _, _) do
    {rest, [parse_ref(ref, []) | rest_args], context}
  end

  defp parse_ref([], [call = {_, _, _}]), do: call
  defp parse_ref([], so_far), do: {:ref, Enum.reverse(so_far)}
  defp parse_ref([:".*"], so_far), do: {:ptrref, Enum.reverse(so_far)}

  defp parse_ref([:LBRACKET, {:integer, index}, :RBRACKET | rest], so_far) do
    parse_ref(rest, [index | so_far])
  end

  defp parse_ref([:DOT | rest], so_far), do: parse_ref(rest, so_far)

  defp parse_ref([name, :LPAREN | rest], so_far) do
    {call, ref_rest} = parse_call(rest, [])

    ref_name =
      case so_far do
        [] -> name
        list -> {:ref, Enum.reverse([name | list])}
      end

    # note in the future, the call should probably have position information:
    parse_ref(ref_rest, [{ref_name, %{}, call}])
  end

  defp parse_ref([name | rest], so_far), do: parse_ref(rest, [name | so_far])

  defp parse_call([:COMMA | rest], so_far), do: parse_call(rest, so_far)

  defp parse_call([:RPAREN | rest], so_far), do: {Enum.reverse(so_far), rest}

  defp parse_call([argument | rest], so_far), do: parse_call(rest, [argument | so_far])
end
