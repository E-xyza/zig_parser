defmodule Zig.Parser.Statement do
  alias Zig.Parser
  alias Zig.Parser.Const
  alias Zig.Parser.Control
  alias Zig.Parser.Var

  def post_traverse(rest, [{:Statement, args} | rest_args], context, _, _) do
    {rest, [parse(args) | rest_args], context}
  end

  @tagged_content ~w(comptime nosuspend suspend defer)a
  @endings [[], [:SEMICOLON]]

  defp parse([tag, block | ender]) when tag in @tagged_content and ender in @endings do
    raise "eee"
    #   {tag, %StatementOptions{}, block}
  end

  defp parse([:errdefer, block | ender]) when ender in @endings do
    raise "unimplemented"
    #  {:errdefer, %StatementOptions{}, do: block}
  end

  defp parse([:errdefer, :|, name, :|, block | ender]) when ender in @endings do
    raise "unimplemented"
    #  {:errdefer, %StatementOptions{}, payload: name, do: block}
  end

  defp parse([:if | rest]) do
    Control.parse_if(rest)
  end

  defp parse([:comptime | rest_args]) do
    rest_args
    |> parse
    |> Parser.put_opt(:comptime, true)
  end

  defp parse([:var | rest_args]) do
    Var.parse(rest_args)
  end

  defp parse([:const | rest_args]) do
    Const.parse(rest_args)
  end

  defp parse([label, :COLON | rest_args]) do
    rest_args
    |> parse()
    |> Parser.put_opt(:label, label)
  end

  defp parse([:inline | rest_args]) do
    rest_args
    |> parse()
    |> Parser.put_opt(:inline, true)
  end

  defp parse([:for | rest_args]) do
    Control.parse_for(rest_args)
  end

  defp parse([:while | rest_args]) do
    Control.parse_while(rest_args)
  end

  defp parse([:switch | rest_args]) do
    Control.parse_switch(rest_args)
  end

  defp parse([expr | ender]) when ender in @endings do
    expr
  end
end
