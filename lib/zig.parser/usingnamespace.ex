defmodule Zig.Parser.Usingnamespace do
  def post_traverse(
        rest,
        [{:usingnamespace, [:usingnamespace, arg, :SEMICOLON]} | rest_args],
        context,
        _,
        _
      ) do
    {rest, [{:usingnamespace, arg} | rest_args], context}
  end
end
