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
    impliciterror: false,
    builtin: false,
    extern: false,
    export: false,
    pub: false,
    inline: :maybe
  ]

  def post_traverse(rest, [{:FnProto, [:fn | args]} | rest_args], context, loc, col) do
    fun_struct =
      args
      |> parse
      |> Parser.put_location(loc, col)

    {rest, [fun_struct | rest_args], context}
  end

  def post_traverse(
        rest,
        [{:PrimaryTypeExpr, [{:builtin, name} | args]} | rest_args],
        context,
        loc,
        col
      ) do
    fun_struct =
      [name | args]
      |> parse
      |> Map.replace!(:builtin, true)
      |> Parser.put_location(loc, col)

    {rest, [fun_struct | rest_args], context}
  end

  defp parse([name, :LPAREN, {:ParamDeclList, params}, :RPAREN | rest]) do
    parse_decl(rest, %__MODULE__{name: name, params: params})
  end

  defp parse([name, :LPAREN, {:ExprList, params}, :RPAREN]) do
    %__MODULE__{name: name, params: params}
  end

  defp parse_decl([{:align, align} | rest], fun_struct) do
    parse_decl(rest, %{fun_struct | align: align})
  end

  defp parse_decl([{:callconv, {:enum_literal, callconv}} | rest], fun_struct) do
    parse_decl(rest, %{fun_struct | callconv: callconv})
  end

  defp parse_decl([{:linksection, {:enum_literal, linksection}} | rest], fun_struct) do
    parse_decl(rest, %{fun_struct | linksection: linksection})
  end

  defp parse_decl([:! | rest], fun_struct) do
    parse_decl(rest, %{fun_struct | impliciterror: true})
  end

  defp parse_decl([type], fun_struct), do: %{fun_struct | type: type}
end
