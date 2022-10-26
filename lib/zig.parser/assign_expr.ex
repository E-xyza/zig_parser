defmodule Zig.Parser.AssignExpr do
  def post_traverse(
        rest,
        [{__MODULE__, args} | args_rest],
        context,
        _,
        _
      ) do
    {rest, [parse_assign(args) | args_rest], context}
  end

  @assign_operators ~w(*= /= %= += -= <<= >>= &= ^= |= *%= +%= -%= =)a

  defp parse_assign([left, operator, right]) when operator in @assign_operators do
    {operator, left, right}
  end

  defp parse_assign([singleton]), do: singleton
end
