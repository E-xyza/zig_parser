defmodule Zig.Parser.Collected do
  @literals ~w(integer char float string)a

  def literals, do: @literals

  def post_traverse(rest, [collected | args_rest], context, _, _, :IDENTIFIER) do
    {rest, [collected | args_rest], context}
  end

  def post_traverse(rest, ["0x" <> hex | args_rest], context, _, _, :INTEGER) do
    {rest, [{:integer, String.to_integer(remove_underscore(hex), 16)} | args_rest], context}
  end

  def post_traverse(rest, ["0o" <> oct | args_rest], context, _, _, :INTEGER) do
    {rest, [{:integer, String.to_integer(remove_underscore(oct), 8)} | args_rest], context}
  end

  def post_traverse(rest, ["0b" <> bin | args_rest], context, _, _, :INTEGER) do
    {rest, [{:integer, String.to_integer(remove_underscore(bin), 16)} | args_rest], context}
  end

  def post_traverse(rest, [integer | args_rest], context, _, _, :INTEGER) do
    {rest, [{:integer, String.to_integer(remove_underscore(integer))} | args_rest], context}
  end

  def post_traverse(rest, [<<?', char, ?'>> | args_rest], context, _, _, :CHAR_LITERAL) do
    {rest, [{:char, char} | args_rest], context}
  end

  def post_traverse(rest, [float | args_rest], context, _, _, :FLOAT) do
    {rest, [{:float, String.to_float(remove_underscore(float))} | args_rest], context}
  end

  def post_traverse(rest, [string | args_rest], context, _, _, :STRINGLITERAL) do
    {rest, [{:string, String.trim(string, ~S("))} | args_rest], context}
  end

  defp remove_underscore(string), do: String.replace(string, "_", "")
end
