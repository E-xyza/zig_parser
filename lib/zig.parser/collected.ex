defmodule Zig.Parser.Collected do
  @literals ~w[integer char float string]a

  def literals, do: @literals

  def post_traverse(rest, [string | args_rest], context, _, _, :line_string) do
    {rest, [string | args_rest], context}
  end

  # zig 0.17 merged INTEGER and FLOAT into one NUMBERLITERAL rule, so the
  # literal's text is what distinguishes them here.
  def post_traverse(rest, ["0x" <> hex | args_rest], context, _, _, :NUMBERLITERAL) do
    parse_based(rest, hex, 16, args_rest, context)
  end

  def post_traverse(rest, ["0o" <> oct | args_rest], context, _, _, :NUMBERLITERAL) do
    parse_based(rest, oct, 8, args_rest, context)
  end

  def post_traverse(rest, ["0b" <> bin | args_rest], context, _, _, :NUMBERLITERAL) do
    parse_based(rest, bin, 2, args_rest, context)
  end

  def post_traverse(rest, [number | args_rest], context, _, _, :NUMBERLITERAL) do
    token =
      number
      |> remove_underscore()
      |> parse_decimal()

    {rest, [token | args_rest], context}
  end

  def post_traverse(rest, [string | args_rest], context, _, _, :STRINGLITERAL) do
    {rest, [{:string, String.trim(string, ~S("))} | args_rest], context}
  end

  def post_traverse(rest, [string | args_rest], context, _, _, :BUILTINIDENTIFIER) do
    builtin =
      string
      |> String.trim_leading("@")
      |> String.to_atom()

    {rest, [{:builtin, builtin} | args_rest], context}
  end

  # a based literal (0x/0o/0b) is always an integer, but it may carry a
  # hex float's '.' or 'p' exponent, in which case we cannot represent it.
  defp parse_based(rest, digits, base, args_rest, context) do
    cleaned = remove_underscore(digits)

    token =
      case Integer.parse(cleaned, base) do
        {integer, ""} -> {:integer, integer}
        _ -> {:extended_float, cleaned}
      end

    {rest, [token | args_rest], context}
  end

  defp parse_decimal(cleaned) do
    cond do
      String.contains?(cleaned, [".", "e", "E"]) ->
        parse_float(cleaned)

      true ->
        case Integer.parse(cleaned) do
          {integer, ""} -> {:integer, integer}
          # zig 0.17's NUMBERLITERAL rule deliberately matches malformed
          # literals (e.g. `0xz`) and leaves rejecting them to the compiler.
          _ -> {:extended_float, cleaned}
        end
    end
  rescue
    ArgumentError -> {:extended_float, cleaned}
  end

  defp parse_float(cleaned) do
    case Float.parse(cleaned) do
      {float, ""} -> {:float, float}
      _ -> {:extended_float, cleaned}
    end
  rescue
    ArgumentError -> {:extended_float, cleaned}
  end

  defp remove_underscore(string), do: String.replace(string, "_", "")
end
