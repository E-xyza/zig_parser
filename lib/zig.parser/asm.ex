defmodule Zig.Parser.AsmOptions do
  defstruct [:position, volatile: false]
end

defmodule Zig.Parser.Asm do
  alias Zig.Parser
  alias Zig.Parser.AsmOptions

  def post_traverse(
        rest,
        [{__MODULE__, [:asm, :LPAREN, expr, :COLON | args]} | args_rest],
        context,
        _,
        _
      ) do
    {rest, [parse_output(args, expr: expr) | args_rest], context}
  end

  def post_traverse(
        rest,
        [{__MODULE__, [:asm, :volatile, :LPAREN, expr, :COLON | args]} | args_rest],
        context,
        _,
        _
      ) do
    asm_ast =
      args
      |> parse_output(expr: expr)
      |> Parser.put_opt(:volatile, true)

    {rest, [asm_ast | args_rest], context}
  end

  def parse_output([:COLON | rest], parts) do
    parse_input(rest, reverse(parts, :outputs))
  end

  def parse_output([:COMMA | rest], parts) do
    parse_output(rest, parts)
  end

  def parse_output(
        [
          :LBRACKET,
          id,
          :RBRACKET,
          {:string, code},
          :LPAREN,
          :MINUSRARROW,
          type,
          :RPAREN | rest
        ],
        parts
      ) do
    new_parts =
      Keyword.update(parts, :outputs, [{id, code, {:->, type}}], &[{id, code, {:->, type}} | &1])

    parse_output(rest, new_parts)
  end

  def parse_output(
        [
          :LBRACKET,
          id,
          :RBRACKET,
          {:string, code},
          :LPAREN,
          identifier,
          :RPAREN | rest
        ],
        parts
      ) do
    new_parts =
      Keyword.update(parts, :outputs, [{id, code, identifier}], &[{id, code, identifier} | &1])

    parse_output(rest, new_parts)
  end

  def parse_input([:COLON | rest], parts) do
    parse_clobbers(rest, reverse(parts, :inputs))
  end

  def parse_input(
        [
          :LBRACKET,
          id,
          :RBRACKET,
          {:string, code},
          :LPAREN,
          type,
          :RPAREN | rest
        ],
        parts
      ) do
    new_parts = Keyword.update(parts, :inputs, [{id, code, type}], &[{id, code, type} | &1])
    parse_input(rest, new_parts)
  end

  def parse_input([:COMMA | rest], parts) do
    parse_input(rest, parts)
  end

  def parse_clobbers([:RPAREN], parts) do
    {:asm, %AsmOptions{}, reverse(parts, :clobbers)}
  end

  def parse_clobbers([{:string, string} | rest], parts) do
    new_parts = Keyword.update(parts, :clobbers, [string], &[string | &1])

    parse_clobbers(rest, new_parts)
  end

  def parse_clobbers([:COMMA | rest], parts) do
    parse_clobbers(rest, parts)
  end

  defp reverse(parts, field) do
    Keyword.update(parts, field, [], &Enum.reverse/1)
  end
end
