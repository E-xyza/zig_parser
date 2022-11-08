defmodule Zig.Parser.StructOptions do
  defstruct extern: false, packed: false, doc_comment: nil
end

defmodule Zig.Parser.OpaqueOptions do
  defstruct extern: false, packed: false, doc_comment: nil
end

defmodule Zig.Parser.EnumOptions do
  defstruct extern: false, packed: false, doc_comment: nil, type: nil
end

defmodule Zig.Parser.UnionOptions do
  defstruct extern: false, packed: false, doc_comment: nil, tagtype: nil, tagged: false
end

defmodule Zig.Parser.PrimaryTypeExpr do
  alias Zig.Parser
  alias Zig.Parser.Control
  alias Zig.Parser.EnumOptions
  alias Zig.Parser.Function
  alias Zig.Parser.OpaqueOptions
  alias Zig.Parser.StructOptions
  alias Zig.Parser.UnionOptions

  def post_traverse(rest, [{:PrimaryTypeExpr, args} | args_rest], context, _, _) do
    {rest, [parse(args) | args_rest], context}
  end

  def _parse(a), do: parse(a)

  defp parse([{:builtin, name}, :LPAREN | builtin_args]) do
    {:builtin, name, parse_builtin(builtin_args, [])}
  end

  @containers ~w(struct opaque enum union)a
  @container_opts %{
    struct: %StructOptions{},
    opaque: %OpaqueOptions{},
    enum: %EnumOptions{},
    union: %UnionOptions{}
  }

  defp parse([:DOT, map]) when is_map(map) do
    {:anonymous_struct, map}
  end

  defp parse([:DOT, list]) when is_list(list) do
    {:tuple, list}
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

  defp parse([:error, :LBRACE | errorset]), do: parse_errorset(errorset, [])

  defp parse([:error, :DOT, error]), do: {:error, error}

  # FnProto
  defp parse(fnproto = [:fn | _rest]), do: Function.parse(fnproto)

  # GroupedExpr
  defp parse([:LPAREN, expr, :RPAREN]), do: expr

  # LabeledExpr
  defp parse([label, :COLON, expr]), do: Parser.put_opt(expr, :label, label)

  # SwitchExpr

  defp parse([:switch | rest]), do: Control.parse_switch(rest)

  defp parse([any]), do: any

  defp parse_builtin([:RPAREN], parts), do: Enum.reverse(parts)
  defp parse_builtin([:COMMA | rest], parts), do: parse_builtin(rest, parts)
  defp parse_builtin([value | rest], parts), do: parse_builtin(rest, [value | parts])

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

  defp parse_errorset([:RBRACE], so_far), do: {:errorset, Enum.reverse(so_far)}

  defp parse_errorset([:COMMA | rest], so_far), do: parse_errorset(rest, so_far)

  defp parse_errorset([identifier | rest], so_far),
    do: parse_errorset(rest, [identifier | so_far])
end
