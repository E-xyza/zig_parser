defmodule Zig.Parser.VarDeclExprStatement do
  alias Zig.Parser.Const 
  alias Zig.Parser.Var

  def post_traverse(rest, args, context, _, _) do
    {rest, parse(args), context}
  end

  # NOTE: this duplicates functionality in `AssignExpr`.
  # this is due to the organization of `grammar.y`
  @assign_operators ~w[*= /= %= += -= <<= >>= &= ^= |= *%= +%= -%= *|= +|= -|= <<|= =]a

  defp parse(args) do
    case Enum.reverse(args) do
      [%m{} = const_or_var | rest] when m in [Const, Var] ->
        {struct, new_rest} = m.extend(const_or_var, rest)
        [struct | new_rest]
      [left, operator, right, :SEMICOLON | rest] when operator in @assign_operators ->
        [{operator, left, right} | rest]
      [left, :"-|", right, :SEMICOLON | rest] ->
        [{:"-|=", left, right} | rest]
      [content, :SEMICOLON] ->
        [content]
    end
  end
end