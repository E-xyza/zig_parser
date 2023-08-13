defmodule Zig.Parser.TypeExpr do
  @literals Zig.Parser.Collected.literals()

  alias Zig.Parser
  alias Zig.Parser.Pointer

  def post_traverse(rest, [{:TypeExpr, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([literalterm = {literal, _}]) when literal in @literals, do: literalterm
  defp parse([:DOT, enum]), do: {:enumliteral, enum}
  defp parse([:LBRACKET, :RBRACKET | _] = slice), do: Pointer.parse(slice)
  defp parse([:LBRACKET, :COLON | _] = slice), do: Pointer.parse(slice)
  defp parse([:LBRACKET, :* | _] = manyptr), do: Pointer.parse(manyptr)
  defp parse([:* | _] = pointer), do: Pointer.parse(pointer)
  defp parse([:** | rest]), do: %Pointer{count: :one, type: parse([:* | rest])}
  defp parse([:QUESTIONMARK, rest]), do: {:optional_type, rest}
  defp parse([:anyframe, :MINUSRARROW, rest]), do: {:anyframe, rest}
  #
  #  defp parse([:async | call]) do
  #    call
  #    |> parse_ref_or_call([])
  #    |> Parser.put_opt(:async, true)
  #  end
  #
  #  defp parse([:LBRACKET, :*, :LETTERC | rest]), do: parse_ptr_type(rest, :cptr)
  #  defp parse([:LBRACKET, :* | rest]), do: parse_ptr_type(rest, :multiptr)
  #  defp parse([:LBRACKET, :RBRACKET | rest]), do: parse_ptr_type([:RBRACKET | rest], :slice)
  #  defp parse([:LBRACKET, :COLON | rest]), do: parse_ptr_type([:COLON | rest], :slice)
  #  defp parse([:LBRACKET | rest]), do: parse_ptr_type(rest, :array)
  #  defp parse([:* | rest]), do: parse_ptr_type(rest, :ptr)
  #  # defp parse([:** | rest]), do: {:ptr, %PointerOptions{}, parse_ptr_type(rest, :ptr)}
  #  defp parse([left, :! | right]), do: parse_error_union(left, right)
  #  defp parse([expr]), do: expr
  #  defp parse(ref_or_call), do: parse_ref_or_call(ref_or_call, [])
  #
  @boolean_slice_opts ~w[allowzero const volatile]a
  #  @bracketed ~w[slice multiptr cptr array]a
  #
  #  defp parse_ptr_type([:RBRACKET | rest], class) when class in @bracketed do
  #    parse_ptr_opts(rest, class)
  #  end
  #
  #  defp parse_ptr_type([:COLON, sentinel, :RBRACKET | rest], class) when class in @bracketed do
  #    {^class, opts, parts} = parse_ptr_opts(rest, class)
  #    {class, opts, parts ++ [sentinel: sentinel]}
  #  end
  #
  #  defp parse_ptr_type([length | rest], :array) do
  #    {:array, opts, parts} = parse_ptr_type(rest, :array)
  #    {:array, opts, Keyword.put(parts, :length, length)}
  #  end
  #
  #  defp parse_ptr_type(rest, :ptr) do
  #    parse_ptr_opts(rest, :ptr)
  #  end
  #
  #  defp parse_ptr_opts([:alignment, :LPAREN, align, :RPAREN | rest], ptr_class) do
  #    rest
  #    |> parse_ptr_opts(ptr_class)
  #    |> Parser.put_opt(:alignment, align)
  #  end
  #
  #  defp parse_ptr_opts(
  #         [:alignment, :LPAREN, align, :COLON, {:integer, a1}, :COLON, {:integer, a2}, :RPAREN | rest],
  #         ptr_class
  #       ) do
  #    rest
  #    |> parse_ptr_opts(ptr_class)
  #    |> Parser.put_opt(:alignment, {align, a1, a2})
  #  end
  #
  #  defp parse_ptr_opts([opt | rest], ptr_class) when opt in @boolean_slice_opts do
  #    rest
  #    |> parse_ptr_opts(ptr_class)
  #    |> Parser.put_opt(opt, true)
  #  end
  #
  #  # defp parse_ptr_opts(what, ptr_class), do: {ptr_class, %PointerOptions{}, type: parse(what)}
  #
  #  defp parse_error_union(left, [{:errorunion, right}]), do: {:errorunion, [left | right]}
  #  defp parse_error_union(left, right), do: {:errorunion, [left | right]}
end
