defmodule Zig.Parser.AssignExpr do
  #  alias Zig.Parser.OperatorOptions

  def post_traverse(
        rest,
        [{:AssignExpr, args} | args_rest],
        context,
        _,
        _
      ) do
    {rest, [parse_assign(args) | args_rest], context}
  end

  @assign_operators ~w[*= /= %= += -= <<= >>= &= ^= |= *%= +%= -%= *|= +|= -|= <<|= =]a

  defp parse_assign([left, operator, right]) when operator in @assign_operators do
    {operator, left, right}
  end

  defp parse_assign([left, :"-|", right]) do
    {:"-|=", left, right}
  end

  # Multi-value destructuring: a, b = value
  defp parse_assign([first | rest]) do
    case parse_multi_assign(rest, [first]) do
      {:multi, targets, value} -> {:=, targets, value}
      :not_multi -> first
    end
  end

  defp parse_multi_assign([:COMMA, expr | rest], targets) do
    parse_multi_assign(rest, [expr | targets])
  end

  defp parse_multi_assign([:=, value], targets) do
    {:multi, Enum.reverse(targets), value}
  end

  defp parse_multi_assign([], [_single]) do
    :not_multi
  end
end
