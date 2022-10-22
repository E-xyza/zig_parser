defmodule Zig.Parser.Asm do
  @enforce_keys [:expr]
  defstruct @enforce_keys ++ [volatile: false, outputs: [], inputs: [], clobbers: []]

  def post_traverse(
        rest,
        [{__MODULE__, [:asm, :LPAREN, expr, :COLON | args]} | args_rest],
        context,
        _,
        _
      ) do
    {rest, [process_output(%__MODULE__{expr: expr}, args) | args_rest], context}
  end

  def post_traverse(
        rest,
        [{__MODULE__, [:asm, :volatile, :LPAREN, expr, :COLON | args]} | args_rest],
        context,
        _,
        _
      ) do
    {rest, [process_output(%__MODULE__{expr: expr, volatile: true}, args) | args_rest], context}
  end

  def process_output(asm, [:COLON | rest]) do
    asm
    |> reverse(:outputs)
    |> process_input(rest)
  end

  def process_output(asm, [:COMMA | rest]) do
    process_output(asm, rest)
  end

  def process_output(asm, [
        :LBRACKET,
        id,
        :RBRACKET,
        {:string, code},
        :LPAREN,
        :MINUSRARROW,
        type,
        :RPAREN | rest
      ]) do
    process_output(%{asm | outputs: [{id, code, type} | asm.outputs]}, rest)
  end

  def process_output(asm, [
        :LBRACKET,
        id,
        :RBRACKET,
        {:string, code},
        :LPAREN,
        type,
        :RPAREN | rest
      ]) do
    process_output(%{asm | outputs: [{id, code, type} | asm.outputs]}, rest)
  end

  def process_input(asm, [:COLON | rest]) do
    asm
    |> reverse(:inputs)
    |> process_clobbers(rest)
  end

  def process_input(asm, [
        :LBRACKET,
        id,
        :RBRACKET,
        {:string, code},
        :LPAREN,
        type,
        :RPAREN | rest
      ]) do
    process_input(%{asm | inputs: [{id, code, type} | asm.inputs]}, rest)
  end

  def process_input(asm, [:COMMA | rest]) do
    process_input(asm, rest)
  end

  def process_clobbers(asm, [:RPAREN]) do
    reverse(asm, :clobbers)
  end

  def process_clobbers(asm, [{:string, string} | rest]) do
    process_clobbers(%{asm | clobbers: [string | asm.clobbers] }, rest)
  end

  def process_clobbers(asm, [:COMMA | rest]) do
    process_clobbers(asm, rest)
  end

  defp reverse(asm, field) do
    reversed =
      asm
      |> Map.fetch!(field)
      |> Enum.reverse()

    %{asm | field => reversed}
  end
end
