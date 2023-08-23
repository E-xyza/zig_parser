defmodule Zig.Parser.ComptimeDecl do
  def post_traverse(rest, [{:ComptimeDecl, [:comptime, content]} | rest_args], context, _, _) do
    {rest, [%{content | comptime: true} | rest_args], context}
  end
end
