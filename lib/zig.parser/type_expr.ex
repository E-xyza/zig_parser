defmodule Zig.Parser.PointerOptions do
  defstruct [:align, const: false, volatile: false, allowzero: false]
end

defmodule Zig.Parser.CallOptions do
  defstruct [:position, async: false]
end

defmodule Zig.Parser.TypeExpr do
  @literals Zig.Parser.Collected.literals()

  alias Zig.Parser
  alias Zig.Parser.CallOptions
  alias Zig.Parser.PointerOptions

  def post_traverse(rest, [{:TypeExpr, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  defp parse([literalterm = {literal, _}]) when literal in @literals, do: literalterm
  defp parse([:DOT, enum]), do: {:enumliteral, enum}
  defp parse([identifier, :".?"]), do: decorate([identifier], :required)
  defp parse([identifier, :".*"]), do: decorate([identifier], :ptrref)
  defp parse([:QUESTIONMARK | ref_or_call]), do: decorate(ref_or_call, :optional_type)
  defp parse([:anyframe, :MINUSRARROW | ref_or_call]), do: decorate(ref_or_call, :anyframe)

  defp parse([:async | call]) do
    call
    |> parse_ref_or_call([])
    |> Parser.put_opt(:async, true)
  end

  defp parse([:LBRACKET, :*, :LETTERC | rest]), do: parse_ptr_type(rest, :cptr)
  defp parse([:LBRACKET, :* | rest]), do: parse_ptr_type(rest, :multiptr)
  defp parse([:LBRACKET, :RBRACKET | rest]), do: parse_ptr_type([:RBRACKET | rest], :slice)
  defp parse([:LBRACKET, :COLON | rest]), do: parse_ptr_type([:COLON | rest], :slice)
  defp parse([:LBRACKET | rest]), do: parse_ptr_type(rest, :array)
  defp parse([:* | rest]), do: parse_ptr_type(rest, :ptr)
  defp parse([:** | rest]), do: {:ptr, %PointerOptions{}, parse_ptr_type(rest, :ptr)}
  defp parse([left, :! | right]), do: parse_error_union(left, right)
  defp parse([expr]), do: expr
  defp parse(ref_or_call), do: parse_ref_or_call(ref_or_call, [])

  defp decorate([expr], decorator), do: {decorator, expr}
  defp decorate(ref_or_call, decorator), do: {decorator, parse_ref_or_call(ref_or_call, [])}

  defp parse_ref_or_call([], [call = {_, _, _}]), do: call
  defp parse_ref_or_call([], so_far), do: {:ref, Enum.reverse(so_far)}
  defp parse_ref_or_call([:".?"], so_far), do: {:required, Enum.reverse(so_far)}
  defp parse_ref_or_call([:".*"], so_far), do: {:ptrref, Enum.reverse(so_far)}

  defp parse_ref_or_call([:LBRACKET, index, :RBRACKET | rest], so_far) do
    parse_ref_or_call(rest, [{:index, index} | so_far])
  end

  defp parse_ref_or_call([:LBRACKET, index, :DOT2, :RBRACKET | rest], so_far) do
    parse_ref_or_call(rest, [{:slice, index, :end} | so_far])
  end

  defp parse_ref_or_call([:LBRACKET, index1, :DOT2, index2, :RBRACKET | rest], so_far) do
    parse_ref_or_call(rest, [{:slice, index1, index2} | so_far])
  end

  defp parse_ref_or_call(
         [:LBRACKET, index1, :DOT2, index2, :COLON, sentinel, :RBRACKET | rest],
         so_far
       ) do
    parse_ref_or_call(rest, [{:slice, index1, index2, sentinel: sentinel} | so_far])
  end

  defp parse_ref_or_call([:DOT | rest], so_far), do: parse_ref_or_call(rest, so_far)

  defp parse_ref_or_call([name, :LPAREN | rest], so_far) do
    {call, ref_rest} = parse_call(rest, [])

    ref_name =
      case so_far do
        [] -> name
        list -> {:ref, Enum.reverse([name | list])}
      end

    parse_ref_or_call(ref_rest, [{ref_name, %CallOptions{}, call}])
  end

  defp parse_ref_or_call([name | rest], so_far), do: parse_ref_or_call(rest, [name | so_far])

  defp parse_call([:COMMA | rest], so_far), do: parse_call(rest, so_far)

  defp parse_call([:RPAREN | rest], so_far), do: {Enum.reverse(so_far), rest}

  defp parse_call([argument | rest], so_far), do: parse_call(rest, [argument | so_far])

  @boolean_slice_opts ~w(allowzero const volatile)a
  @bracketed ~w(slice multiptr cptr array)a

  defp parse_ptr_type([:RBRACKET | rest], class) when class in @bracketed do
    parse_ptr_opts(rest, class)
  end

  defp parse_ptr_type([:COLON, sentinel, :RBRACKET | rest], class) when class in @bracketed do
    {^class, opts, parts} = parse_ptr_opts(rest, class)
    {class, opts, parts ++ [sentinel: sentinel]}
  end

  defp parse_ptr_type([length | rest], :array) do
    {:array, opts, parts} = parse_ptr_type(rest, :array)
    {:array, opts, Keyword.put(parts, :length, length)}
  end

  defp parse_ptr_type(rest, :ptr) do
    parse_ptr_opts(rest, :ptr)
  end

  defp parse_ptr_opts([:align, :LPAREN, align, :RPAREN | rest], ptr_class) do
    rest
    |> parse_ptr_opts(ptr_class)
    |> Parser.put_opt(:align, align)
  end

  defp parse_ptr_opts(
         [:align, :LPAREN, align, :COLON, {:integer, a1}, :COLON, {:integer, a2}, :RPAREN | rest],
         ptr_class
       ) do
    rest
    |> parse_ptr_opts(ptr_class)
    |> Parser.put_opt(:align, {align, a1, a2})
  end

  defp parse_ptr_opts([opt | rest], ptr_class) when opt in @boolean_slice_opts do
    rest
    |> parse_ptr_opts(ptr_class)
    |> Parser.put_opt(opt, true)
  end

  defp parse_ptr_opts(what, ptr_class), do: {ptr_class, %PointerOptions{}, type: parse(what)}

  defp parse_error_union(left, [{:errorunion, right}]), do: {:errorunion, [left | right]}
  defp parse_error_union(left, right), do: {:errorunion, [left | right]}
end
