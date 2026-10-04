defmodule Zig.Parser do
  require Pegasus
  import NimbleParsec

  defstruct [:doc_comment, :source, code: [], dependencies: [], comments: []]

  @external_resource "lib/grammar/grammar.peg"

  alias Zig.Parser.Asm
  alias Zig.Parser.AssignExpr
  alias Zig.Parser.Block
  alias Zig.Parser.Collected
  alias Zig.Parser.ComptimeDecl
  alias Zig.Parser.ContainerDecl
  alias Zig.Parser.ContainerDeclaration
  alias Zig.Parser.Decl
  alias Zig.Parser.ErrorUnionExpr
  alias Zig.Parser.Expr
  alias Zig.Parser.For
  alias Zig.Parser.GlobalVarDecl
  alias Zig.Parser.InitList
  alias Zig.Parser.Test
  alias Zig.Parser.Function
  alias Zig.Parser.ParamDecl
  alias Zig.Parser.ParseError
  alias Zig.Parser.PrimaryExpr
  alias Zig.Parser.PrimaryTypeExpr
  alias Zig.Parser.Statement
  alias Zig.Parser.TypeExpr
  alias Zig.Parser.VarDeclProto
  alias Zig.Parser.VarAssignStatement
  alias Zig.Parser.While

  @keywords ~w[addrspace align allowzero and anyframe anytype asm break callconv catch comptime const continue defer else enum errdefer error export extern fn for if inline noalias nosuspend noinline opaque or orelse packed pub resume return linksection struct suspend switch test threadlocal try union unreachable var volatile while]a
  @keyword_mapping Enum.map(@keywords, &{:"KEYWORD_#{&1}", [token: &1]})

  @sub_operators %{
    AMPERSAND: :&,
    AMPERSANDEQUAL: :"&=",
    ASTERISK: :*,
    ASTERISK2: :**,
    ASTERISKEQUAL: :"*=",
    ASTERISKPERCENT: :"*%",
    ASTERISKPERCENTEQUAL: :"*%=",
    ASTERISKPIPE: :"*|",
    ASTERISKPIPEEQUAL: :"*|=",
    CARET: :^,
    CARETEQUAL: :"^=",
    DOT3: :...,
    DOTASTERISK: :".*",
    DOTQUESTIONMARK: :".?",
    EQUAL: :=,
    EQUALEQUAL: :==,
    EQUALRARROW: :"=>",
    EXCLAMATIONMARK: :!,
    EXCLAMATIONMARKEQUAL: :!=,
    LARROW: :<,
    LARROW2: :"<<",
    LARROW2EQUAL: :"<<=",
    LARROW2PIPE: :"<<|",
    LARROW2PIPEEQUAL: :"<<|=",
    LARROWEQUAL: :<=,
    MINUS: :-,
    MINUSEQUAL: :"-=",
    MINUSPERCENT: :"-%",
    MINUSPERCENTEQUAL: :"-%=",
    MINUSPIPE: :"-|",
    MINUSPIPEEQUAL: :"-|",
    PERCENT: :%,
    PERCENTEQUAL: :"%=",
    PIPE: :|,
    PIPE2: :||,
    PIPEEQUAL: :"|=",
    PLUS: :+,
    PLUS2: :++,
    PLUSEQUAL: :"+=",
    PLUSPERCENT: :"+%",
    PLUSPERCENTEQUAL: :"+%=",
    PLUSPIPE: :"+|",
    PLUSPIPEEQUAL: :"+|=",
    RARROW: :>,
    RARROW2: :">>",
    RARROW2EQUAL: :">>=",
    RARROWEQUAL: :>=,
    SLASH: :/,
    SLASHEQUAL: :"/=",
    TILDE: :"~"
  }

  @sub_operator_mapping Enum.map(@sub_operators, fn {name, op} ->
                          {name, [token: op, start_position: true]}
                        end)

  @operators ~w[COMMA DOT DOT2 COLON LBRACE LBRACKET LPAREN MINUSRARROW LETTERC QUESTIONMARK RBRACE RBRACKET RPAREN SEMICOLON]a
  @operator_mapping Enum.map(@operators, &{&1, [token: true]})

  # zig 0.17 merged INTEGER and FLOAT into a single NUMBERLITERAL rule.
  @collecteds ~w[NUMBERLITERAL BUILTINIDENTIFIER]a
  @collected_mapping Enum.map(
                       @collecteds,
                       &{&1, [collect: true, post_traverse: {Collected, :post_traverse, [&1]}]}
                     )

  @lists ~w[IdentifierList SwitchProngList AsmOutputList AsmInputList StringList ParamDeclList ExprList]a
  # Zig 0.17 rewrote the list rules to be right-recursive so the grammar is LL(k):
  # `SwitchProngList <- (SwitchProng (COMMA SwitchProngList)?)?` instead of
  # `(SwitchProng COMMA)* SwitchProng?`.  That nests each tail inside a tagged
  # sublist, so flatten them back into the flat token runs the handlers expect.
  @lists_mapping Enum.map(@lists, &{&1, tag: true, post_traverse: {__MODULE__, :flatten_list, [&1]}})

  @doc false
  def flatten_list(rest, [{tag, args} | rest_args], context, _, _, tag) do
    {rest, [{tag, do_flatten_list(args, tag)} | rest_args], context}
  end

  def flatten_list(rest, args, context, _, _, _tag), do: {rest, args, context}

  # Accumulate in reverse so a long list is flattened in one pass rather than
  # rebuilding the prefix at every nesting level.
  defp do_flatten_list(args, tag), do: do_flatten_list(args, tag, [])

  defp do_flatten_list([{tag, inner}], tag, acc), do: do_flatten_list(inner, tag, acc)
  defp do_flatten_list([head | tail], tag, acc), do: do_flatten_list(tail, tag, [head | acc])
  defp do_flatten_list([], _tag, acc), do: :lists.reverse(acc)

  @parser_options [
                    container_doc_comment: [
                      tag: :doc_comment,
                      post_traverse: :doc_comment
                    ],
                    doc_comment: [post_traverse: :doc_comment, tag: true],
                    line_comment: [post_traverse: :line_comment, tag: true, start_position: true],
                    line_string: [collect: true, post_traverse: :process_line_string],
                    AssignExpr: [
                      tag: true,
                      post_traverse: {AssignExpr, :post_traverse, []}
                    ],
                    SingleAssignExpr: [
                      tag: :AssignExpr,
                      post_traverse: {AssignExpr, :post_traverse, []}
                    ],
                    TestDecl: [
                      tag: true,
                      start_position: true,
                      post_traverse: {Test, :post_traverse, []}
                    ],
                    Decl: [
                      tag: true,
                      post_traverse: {Decl, :post_traverse, []}
                    ],
                    # zig 0.17 renamed the type literal rule ContainerDecl -> ContainerType
                    # and the top level declaration rule ContainerDeclaration -> ContainerDecl.
                    # The two names swapped meanings, so mind the mapping here.
                    ContainerType: [
                      start_position: true,
                      tag: true,
                      post_traverse: {ContainerDecl, :post_traverse, []}
                    ],
                    ContainerDecl: [
                      tag: true,
                      post_traverse: {ContainerDeclaration, :post_traverse, []}
                    ],
                    PrimaryExpr: [
                      start_position: true,
                      tag: true,
                      post_traverse: {PrimaryExpr, :post_traverse, []}
                    ],
                    skip: [ignore: true],
                    # zig 0.17 added these around operators to require symmetric
                    # spacing; they carry no syntax tree meaning.
                    pre_op_white: [ignore: true],
                    post_op_white: [ignore: true],
                    skip_require_newline: [ignore: true],
                    byte_order_mark: [ignore: true],
                    byte_order_mark: [ignore: true],
                    IDENTIFIER: [post_traverse: :identifier],
                    STRINGLITERALSINGLE: [
                      tag: :string,
                      post_traverse: :literal_stringlike
                    ],
                    CHAR_LITERAL: [
                      tag: :char,
                      post_traverse: :literal_stringlike
                    ],
                    STRINGLITERAL: [
                      post_traverse: :string_literal
                    ],
                    ComptimeDecl: [
                      tag: true,
                      post_traverse: {ComptimeDecl, :post_traverse, []}
                    ],
                    TypeExpr: [
                      tag: true,
                      post_traverse: {TypeExpr, :post_traverse, []}
                    ],
                    Expr: [
                      tag: true,
                      post_traverse: {Expr, :post_traverse, []}
                    ],
                    ErrorUnionExpr: [
                      tag: true,
                      post_traverse: {ErrorUnionExpr, :post_traverse, []}
                    ],
                    InitList: [
                      tag: true,
                      post_traverse: {InitList, :post_traverse, []}
                    ],
                    ParamDecl: [tag: true, post_traverse: {ParamDecl, :post_traverse, []}],
                    VarDeclProto: [
                      start_position: true,
                      tag: true,
                      post_traverse: {VarDeclProto, :post_traverse, []}
                    ],
                    PrefixTypeOp: [tag: true],
                    PrimaryTypeExpr: [
                      tag: true,
                      post_traverse: {PrimaryTypeExpr, :post_traverse, []}
                    ],
                    SwitchItem: [tag: true],
                    AsmExpr: [
                      start_position: true,
                      tag: true,
                      post_traverse: {Asm, :post_traverse, []}
                    ],
                    BlockExpr: [
                      start_position: true,
                      tag: true,
                      post_traverse: {Block, :post_traverse, []}
                    ],
                    Block: [
                      start_position: true,
                      tag: true,
                      post_traverse: {Block, :post_traverse, []}
                    ],
                    FnProto: [
                      start_position: true,
                      tag: true,
                      post_traverse: {Function, :post_traverse, []}
                    ],
                    ForStatement: [tag: true, post_traverse: {For, :post_traverse, []}],
                    WhileStatement: [tag: true, post_traverse: {While, :post_traverse, []}],
                    # zig 0.17 folded ExprStatement into Statement, and renamed the old
                    # Statement to BlockStatement.
                    BlockStatement: [tag: true, post_traverse: {Statement, :post_traverse, []}],
                    Statement: [tag: true, post_traverse: {Statement, :post_traverse, []}],
                    GlobalVarDecl: [post_traverse: {GlobalVarDecl, :post_traverse, []}],
                    VarAssignStatement: [
                      post_traverse: {VarAssignStatement, :post_traverse, []}
                    ],
                    # keywords that add inline
                    LoopStatement: [tag: true, post_traverse: :add_inline],
                    # basic pseudofunction keywords
                    CallConv: [tag: true, post_traverse: :pseudofunction],
                    ByteAlign: [tag: true, post_traverse: :pseudofunction],
                    LinkSection: [tag: true, post_traverse: :pseudofunction],
                    AddrSpace: [tag: true, post_traverse: :pseudofunction],
                    # Top level
                    Root: [tag: true, post_traverse: :post_traverse]
                  ] ++
                    @keyword_mapping ++
                    @operator_mapping ++
                    @sub_operator_mapping ++
                    @collected_mapping ++
                    @lists_mapping

  Pegasus.parser_from_file(Path.join(__DIR__, "grammar/grammar.peg"), @parser_options)

  zig_parser =
    empty()
    |> post_traverse(empty(), :init)
    |> parsec(:Root)

  defparsecp(:parser, zig_parser)

  def parse(string) do
    string
    |> String.replace("\r\n", "\n")
    |> parser
    |> case do
      {:ok, _, "", parser, _, _} ->
        %{
          parser
          | comments: Enum.reverse(parser.comments),
            dependencies: Enum.uniq(parser.dependencies)
        }

      {:error, message, remainder, context, line, column} ->
        raise ParseError,
          message: message,
          remainder: remainder,
          context: context,
          line: line,
          column: column
    end
  end

  # parser combinators

  defp init(code, args, context, _, _) do
    # keep the source around: zig 0.17 moved `skip` to the front of every token
    # rule, so a rule's recorded start position sits *before* any leading
    # whitespace and comments.  put_location/2 walks forward from there.
    {code, args, struct(__MODULE__, Map.put(context, :source, code))}
  end

  defp doc_comment(rest, [{:doc_comment, args} | rest_args], context, _, _) do
    {rest, [{:doc_comment, join_doc_comment(args)} | rest_args], context}
  end

  # zig 0.17 terminates each doc comment line with the `newline` rule, which is
  # a lookahead (`&("\n" / "\r\n" / eof)`) and therefore consumes nothing.  The
  # args arrive as ["///", chars.., "///", chars..] with no separators, so the
  # line breaks are reconstructed from the markers.
  defp join_doc_comment(args) do
    # args arrive in source order as ["///", chars.., "///", chars..], so each
    # marker opens a new line and the characters follow it.
    args
    |> Enum.chunk_while(
      [],
      fn
        marker, [] when marker in ["///", "//!"] -> {:cont, []}
        marker, acc when marker in ["///", "//!"] -> {:cont, Enum.reverse(acc), []}
        char, acc -> {:cont, [char | acc]}
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, Enum.reverse(acc), []}
      end
    )
    |> Enum.map(&[IO.iodata_to_binary(&1), ?\n])
    |> IO.iodata_to_binary()
  end

  # zig 0.17 terminates doc comment lines with the `newline` rule, which is a
  # lookahead (`&("\n" / "\r\n" / eof)`) and so consumes nothing.  The 0.16
  # grammar consumed the newline, and the reported doc comment included it.
  defp end_with_newline(""), do: ""

  defp end_with_newline(binary) do
    if String.ends_with?(binary, "\n"), do: binary, else: binary <> "\n"
  end

  defp line_comment(
         rest,
         [{:line_comment, [position, "//" | comment]} | rest_args],
         context,
         _,
         _
       ) do
    comment_data = {IO.iodata_to_binary(comment), position}
    {rest, rest_args, %{context | comments: [comment_data | context.comments]}}
  end

  defp line_comment(
         rest,
         [{:line_comment, [position, "////" | comment]} | rest_args],
         context,
         _,
         _
       ) do
    comment_data = {IO.iodata_to_binary([?/, ?/, comment]), position}
    {rest, rest_args, %{context | comments: [comment_data | context.comments]}}
  end

  # Zig 0.17 dropped the char_escape grammar rule: char_char/string_char now
  # match a backslash pair literally and the compiler interprets it later.  The
  # parser still reports interpreted values, so the escapes are decoded here.
  @escaped %{?t => "\t", ?r => "\r", ?n => "\n", ?' => "'", ?" => "\"", ?\\ => "\\"}

  @doc false
  def unescape(binary) when is_binary(binary), do: unescape(binary, [])

  defp unescape(<<>>, acc), do: acc |> :lists.reverse() |> IO.iodata_to_binary()

  defp unescape(<<"\\x", hi, lo, rest::binary>>, acc) when hi in ~c"0123456789abcdefABCDEF" and
                                                            lo in ~c"0123456789abcdefABCDEF" do
    unescape(rest, [<<List.to_integer([hi, lo], 16)>> | acc])
  end

  defp unescape(<<"\\u{", rest::binary>>, acc) do
    # A malformed escape is left as written: zig 0.17 no longer validates these
    # in the grammar, and the compiler is what rejects them.
    with [codepoint, tail] <- :binary.split(rest, "}"),
         {value, ""} <- Integer.parse(codepoint, 16),
         <<decoded::utf8>> <- <<value::utf8>> do
      unescape(tail, [<<decoded::utf8>> | acc])
    else
      _ -> unescape(rest, ["\\u{" | acc])
    end
  rescue
    ArgumentError -> unescape(rest, ["\\u{" | acc])
  end

  defp unescape(<<"\\", escaped, rest::binary>>, acc) when is_map_key(@escaped, escaped) do
    unescape(rest, [Map.fetch!(@escaped, escaped) | acc])
  end

  defp unescape(<<char::utf8, rest::binary>>, acc), do: unescape(rest, [<<char::utf8>> | acc])
  defp unescape(<<byte, rest::binary>>, acc), do: unescape(rest, [<<byte>> | acc])

  defp literal_stringlike(rest, [{tag, literal} | rest_args], context, _, _) do
    content =
      literal
      |> Enum.slice(1..-2//1)
      |> IO.iodata_to_binary()
      |> unescape()

    {rest, [{tag, content} | rest_args], context}
  end

  def post_traverse("", [Root: [{:doc_comment, doc_comment} | code]], context, _, _) do
    {"", [], struct(context, code: code, doc_comment: doc_comment)}
  end

  def post_traverse("", [Root: code], context, _, _) do
    {"", [], struct(context, code: code)}
  end

  defp add_inline(rest, [{_tag, [:inline, payload]} | rest_args], context, _loc, _col) do
    {rest, [%{payload | inline: true} | rest_args], context}
  end

  defp add_inline(rest, [{_tag, [payload]} | rest_args], context, _loc, _col) do
    {rest, [payload | rest_args], context}
  end

  defp identifier(rest, [{:string, identifier}, "@" | rest_args], context, _loc, _col) do
    {rest, [{:builtin, String.to_atom(identifier)} | rest_args], context}
  end

  defp identifier(rest, charlist, context, _loc, _col) do
    {rest, [charlist |> Enum.reverse() |> build_identifier()], context}
  end

  # Zig 0.17 spells the quoted identifier form as `'@' string` rather than
  # `'@' STRINGLITERALSINGLE`, so the `@` and the surrounding quotes arrive as
  # plain characters here instead of a pre-collected string token.  Strip them
  # and tag it the way the string-literal path used to.
  defp build_identifier(["@", ?" | rest]) do
    case :lists.reverse(rest) do
      [?" | middle] -> {:builtin, middle |> :lists.reverse() |> to_identifier_atom()}
      _ -> {:builtin, to_identifier_atom(rest)}
    end
  end

  defp build_identifier(charlist), do: to_identifier_atom(charlist)

  # The grammar matches raw bytes, so a multi-byte utf8 identifier arrives as a
  # list of bytes rather than codepoints; rebuild it as a binary before interning.
  defp to_identifier_atom(charlist) do
    # The grammar matches raw bytes, so a multi-byte utf8 identifier arrives as a
    # list of bytes rather than codepoints.  Rebuild it as a binary and only fall
    # back to the byte interpretation when it is not valid utf8.
    binary = :erlang.list_to_binary(charlist)

    if String.valid?(binary) do
      String.to_atom(binary)
    else
      List.to_atom(charlist)
    end
  rescue
    ArgumentError -> List.to_atom(charlist)
  end

  defp string_literal(rest, args, context, _loc, _col) do
    arg =
      case args do
        [{:string, _} = string] ->
          string

        string_list ->
          # Zig 0.17 inlines the `string` rule into STRINGLITERAL rather than
          # going through STRINGLITERALSINGLE, so the surrounding quotes arrive
          # here as ordinary characters and the escapes are still raw.
          {:string,
           string_list
           |> Enum.reverse()
           |> IO.iodata_to_binary()
           |> strip_quotes()
           |> unescape()}
      end

    {rest, [arg], context}
  end

  defp strip_quotes(<<?\", rest::binary>>) when byte_size(rest) > 0 do
    case :binary.last(rest) do
      ?\" -> binary_part(rest, 0, byte_size(rest) - 1)
      _ -> <<?\", rest::binary>>
    end
  end

  defp strip_quotes(binary), do: binary

  defp pseudofunction(
         rest,
         [{_tag, [name, :LPAREN, payload, :RPAREN]} | rest_args],
         context,
         _loc,
         _col
       ) do
    {rest, [{name, payload} | rest_args], context}
  end

  defp process_line_string(rest, args, context, _loc, _col) do
    # Strip the leading \\ and trailing spaces (but keep the newline).
    # zig 0.17 terminates line_string with the `newline` lookahead rather than
    # consuming the newline, so it is restored here.
    str = IO.iodata_to_binary(args)

    new_args =
      str
      |> String.replace_prefix("\\\\", "")
      |> String.replace(~r/\n[ ]*$/, "\n")
      |> end_with_newline()

    {rest, [new_args], context}
  end

  @doc false
  def put_location(struct, location, source \\ nil)

  def put_location(%_{} = struct, location, source) do
    Map.replace!(struct, :location, real_location(location, source))
  end

  # Zig 0.17 puts `skip` at the start of each token rule rather than the end, so
  # the position captured when a rule is entered points at the whitespace and
  # comments preceding the first real token.  Walk forward over those to report
  # the location of the token itself, the way the 0.16 grammar did.
  def real_location(location, nil), do: {location.line, location.column}

  def real_location(location, source) do
    # pegasus reports `offset` as the offset of the start of the line, so the
    # absolute byte position of the captured spot is offset + column - 1.
    absolute = location.offset + location.column - 1

    if absolute >= byte_size(source) do
      {location.line, location.column}
    else
      source
      |> binary_part(absolute, byte_size(source) - absolute)
      |> advance_past_skip(location.line, location.column)
    end
  end

  defp advance_past_skip(<<?\n, rest::binary>>, line, _col), do: advance_past_skip(rest, line + 1, 1)

  defp advance_past_skip(<<c, rest::binary>>, line, col) when c in [?\s, ?\t, ?\r],
    do: advance_past_skip(rest, line, col + 1)

  defp advance_past_skip(<<"//", rest::binary>> = all, line, col) do
    case all do
      <<"///", _::binary>> -> {line, col}
      <<"//!", _::binary>> -> {line, col}
      _ -> skip_to_eol(rest, line, col)
    end
  end

  defp advance_past_skip(_other, line, col), do: {line, col}

  defp skip_to_eol(<<?\n, rest::binary>>, line, _col), do: advance_past_skip(rest, line + 1, 1)
  defp skip_to_eol(<<_, rest::binary>>, line, col), do: skip_to_eol(rest, line, col + 1)
  defp skip_to_eol(<<>>, line, col), do: {line, col}

  def _parse_args([], _), do: []
  def _parse_args([arg], so_far), do: Enum.reverse([arg | so_far])
  def _parse_args([arg, :COMMA | rest], so_far), do: _parse_args(rest, [arg | so_far])
end
