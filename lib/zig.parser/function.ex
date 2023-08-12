defmodule Zig.Parser.Function do
  alias Zig.Parser

  defstruct [
    :location,
    :doc_comment,
    :block,
    :name,
    :params,
    :type,
    :align,
    :linksection,
    :callconv,
    builtin: false,
    extern: false,
    export: false,
    pub: false,
    inline: :maybe
  ]

  def post_traverse(rest, [{:FnProto, [:fn | args]} | rest_args], context, loc, col) do
    fun_struct = args
    |> parse
    |> Parser.put_location(loc, col)

    {rest, [fun_struct | rest_args], context}
  end

  def post_traverse(rest, [{:PrimaryTypeExpr, [{:builtin, name} | args]} | rest_args], context, loc, col) do
    fun_struct = [name | args]
    |> parse
    |> Map.replace!(:builtin, true)
    |> Parser.put_location(loc, col)

    {rest, [fun_struct | rest_args], context}
  end

  defp parse([name, :LPAREN, {:ParamDeclList, params}, :RPAREN, type]) do
    %__MODULE__{name: name, params: params, type: type}
  end

  defp parse([name, :LPAREN, {:ExprList, params}, :RPAREN]) do
    %__MODULE__{name: name, params: params}
  end
end
