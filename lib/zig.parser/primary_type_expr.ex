defmodule Zig.Parser.PrimaryTypeExpr do
  alias Zig.Parser.ErrorSet
  alias Zig.Parser.Function
  alias Zig.Parser.If
  alias Zig.Parser.StructLiteral
  alias Zig.Parser.Switch

  def post_traverse(rest, [{:PrimaryTypeExpr, args} | args_rest], context, _, _) do
    expr = parse(args)

    # modify the context to add dependencies if we have either embedFile or import
    # builtins.

    new_context =
      case expr do
        {:call, :embedFile, [string: path]} ->
          %{context | dependencies: context.dependencies ++ [path]}

        {:call, :import, [string: path]} ->
          if Path.extname(path) == ".zig" do
            %{context | dependencies: context.dependencies ++ [path]}
          else
            context
          end

        _ ->
          context
      end

    {rest, [expr | args_rest], new_context}
  end

  def _parse(a), do: parse(a)

  defp parse([{:builtin, name}, :LPAREN, {:ExprList, args}, :RPAREN]) do
    {:call, name, parse_args(args, [])}
  end

  @containers ~w[struct opaque enum union]a
  @container_opts %{}

  defp parse([:DOT, map]) when is_map(map) do
    %StructLiteral{values: map}
  end

  defp parse([:DOT, list]) when is_list(list) do
    map =
      list
      |> Enum.with_index()
      |> Map.new(fn {value, index} -> {index, value} end)

    %StructLiteral{values: map}
  end

  defp parse([:DOT, {:empty}]), do: {:empty}

  defp parse([:DOT, enum_literal]) do
    {:enum_literal, enum_literal}
  end

  defp parse([:extern | rest]) do
    {container, container_opts, container_code} = parse(rest)
    {container, %{container_opts | extern: true}, container_code}
  end

  defp parse([:packed | rest]) do
    {container, container_opts, container_code} = parse(rest)
    {container, %{container_opts | packed: true}, container_code}
  end

  defp parse([:enum, :LPAREN, expr, :RPAREN, :LBRACE | rest]) do
    {container, container_opts, container_code} = parse([:enum, :LBRACE | rest])
    {container, %{container_opts | type: expr}, container_code}
  end

  defp parse([:union, :LPAREN, :enum, :RPAREN, :LBRACE | rest]) do
    {container, container_opts, container_code} = parse([:union, :LBRACE | rest])
    {container, %{container_opts | tagged: true}, container_code}
  end

  defp parse([:union, :LPAREN, :enum, :LPAREN, enumtype, :RPAREN, :RPAREN, :LBRACE | rest]) do
    {container, container_opts, container_code} = parse([:union, :LBRACE | rest])
    {container, %{container_opts | tagtype: {:enum, enumtype}, tagged: true}, container_code}
  end

  defp parse([:union, :LPAREN, expr, :RPAREN, :LBRACE | rest]) do
    {container, container_opts, container_code} = parse([:union, :LBRACE | rest])
    {container, %{container_opts | tagtype: expr, tagged: true}, container_code}
  end

  defp parse([container, :LBRACE | container_args]) when container in @containers do
    opts = @container_opts[container]

    {opts, rest_args} =
      case container_args do
        [{:doc_comment, [comment]} | rest_args] ->
          comment =
            comment
            |> String.split("\n")
            |> Enum.map(&String.trim/1)
            |> Enum.map(&String.trim_leading(&1, "//!"))
            |> Enum.join("\n")

          {Map.put(opts, :doc_comment, comment), rest_args}

        rest_args ->
          {opts, rest_args}
      end

    {container, opts, parse_container_body(rest_args, [])}
  end

  defp parse(["'", parsed_char, "'"]), do: parsed_char

  # error sets and error literals

  defp parse([:error, :LBRACE | errorset]), do: ErrorSet.parse([:LBRACE | errorset])

  defp parse([:error, :DOT, error]), do: {:error, error}

  # FnProto
  defp parse(fnproto = [:fn | _rest]), do: Function.parse(fnproto)

  # GroupedExpr
  defp parse([:LPAREN, expr, :RPAREN]), do: expr

  # LabeledExpr
  defp parse([label, :COLON, %{} = expr]) do
    %{expr | label: label}
  end

  # IfExpr
  defp parse([:if | ifexpr]), do: If.parse(ifexpr)

  # SwitchExpr
  defp parse([:switch | switch]), do: Switch.parse(switch)

  defp parse([any]), do: any

  defp parse_args([], _), do: []
  defp parse_args([arg], so_far), do: Enum.reverse([arg | so_far])
  defp parse_args([arg, :COMMA | rest], so_far), do: parse_args(rest, [arg | so_far])

  defp parse_container_body([const = {:const, _, _} | rest], parts) do
    new_parts = Keyword.update(parts, :decls, [const], &[const | &1])
    parse_container_body(rest, new_parts)
  end

  defp parse_container_body([identifier, :COLON, type | rest], parts) do
    new_parts = Keyword.update(parts, :fields, [{identifier, type}], &[{identifier, type} | &1])
    parse_container_body(rest, new_parts)
  end

  defp parse_container_body([:COMMA | rest], parts), do: parse_container_body(rest, parts)

  defp parse_container_body([:RBRACE], parts) do
    Enum.reduce([:fields, :decls], parts, fn
      part_label, parts ->
        Keyword.update(parts, part_label, [], &Enum.reverse/1)
    end)
  end

  defp parse_container_body([identifier | rest], parts) do
    # this is for enum fields
    new_parts = Keyword.update(parts, :fields, [identifier], &[identifier | &1])
    parse_container_body(rest, new_parts)
  end
end
