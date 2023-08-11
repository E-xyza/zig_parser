defmodule Zig.Parser.ComptimeDecl do
  alias Zig.Parser

  def post_traverse(rest, [{:ComptimeDecl, [:comptime, content]} | rest_args], context, loc, row) do
    updated_content =
      content
      |> Parser.put_location(loc, row)
      |> Map.replace!(:comptime, true)

    {rest, [updated_content | rest_args], context}
  end
end
