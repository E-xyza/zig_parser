defmodule Zig.Parser.Statement do
  alias Zig.Parser.Const
  alias Zig.Parser.Control
  alias Zig.Parser.Var

  def post_traverse(rest, [{__MODULE__, args} | rest_args], context, _, _) do
    {rest, [parse_statement(args) | rest_args], context}
  end

  @tagged_content ~w(comptime nosuspend suspend defer errdefer)a

  defp parse_statement([_position, tag, block]) when tag in @tagged_content do
    {tag, block}
  end

  defp parse_statement([_position, tag, expr, :SEMICOLON]) when tag in @tagged_content do
    {tag, expr}
  end

  defp parse_statement([_position, :errdefer, :|, name, :|, block]) do
    {:errdefer, {:payload, String.to_atom(name), block}}
  end

  defp parse_statement([_position, :errdefer, :|, name, :|, expr, :SEMICOLON]) do
    {:errdefer, {:payload, String.to_atom(name), expr}}
  end

  defp parse_statement([_position, :if | rest]) do
    Control.parse_if(rest)
  end

  defp parse_statement([position, :comptime | rest_args]) do
    [position | rest_args]
    |> parse_statement()
    |> struct(comptime: true)
  end

  defp parse_statement([position, :var | rest_args]) do
    Var.from_args(rest_args, position)
  end

  defp parse_statement([position, :const | rest_args]) do
    Const.from_args(rest_args, position)
  end

  @for_types [:for, :inline_for]
  @while_types [:while, :inline_while]

  defp parse_statement([position, label, :COLON | rest_args]) do
    label_atom = String.to_atom(label)

    case parse_statement([position | rest_args]) do
      {loop_type, iterator, payload, code, else_code} when loop_type in @for_types ->
        {{loop_type, label_atom}, iterator, payload, code, else_code}

      {loop_type, iterator, payload, code} when loop_type in @for_types ->
        {{loop_type, label_atom}, iterator, payload, code}

      {loop_type, condition, code, else_code} when loop_type in @while_types ->
        {{loop_type, label_atom}, condition, code, else_code}

      {loop_type, condition, code} when loop_type in @while_types ->
        {{loop_type, label_atom}, condition, code}
    end
  end

  defp parse_statement([_position, :for | rest_args]) do
    Control.parse_for(rest_args)
  end

  defp parse_statement([_position, :inline, :while | rest_args]) do
    Control.parse_while(rest_args, true)
  end

  defp parse_statement([_position, :while | rest_args]) do
    Control.parse_while(rest_args)
  end

  defp parse_statement([_position, :inline, :for | rest_args]) do
    Control.parse_for(rest_args, true)
  end

  defp parse_statement([_position, :switch | rest_args]) do
    Control.parse_switch(rest_args)
  end

  defp parse_statement([_position, expr, :SEMICOLON]) do
    expr
  end
end
