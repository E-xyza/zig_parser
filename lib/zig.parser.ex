defmodule Zig.Parser do
  require Pegasus
  import NimbleParsec

  defstruct [:doc_comment, code: [], dependencies: [], comments: []]

  alias Zig.Parser.Asm
  alias Zig.Parser.AssignExpr
  alias Zig.Parser.Block
  alias Zig.Parser.BlockExpr
  alias Zig.Parser.Collected
  alias Zig.Parser.Expr
  alias Zig.Parser.InitList
  alias Zig.Parser.TestDecl
  alias Zig.Parser.TopLevelComptime
  alias Zig.Parser.TopLevelDecl
  alias Zig.Parser.Function
  alias Zig.Parser.PrimaryTypeExpr
  alias Zig.Parser.Statement
  alias Zig.Parser.TopLevelFn
  alias Zig.Parser.TopLevelVar
  alias Zig.Parser.TypeExpr
  alias Zig.Parser.Usingnamespace
  alias Zig.Parser.ParamDecl

  @keywords ~w(align allowzero and anyframe anytype asm async await break callconv catch comptime const continue defer else enum errdefer error export extern fn for if inline noalias nosuspend noinline opaque or orelse packed pub resume return linksection struct suspend switch test threadlocal try union unreachable usingnamespace var volatile while)a
  @keyword_mapping Enum.map(@keywords, &{:"KEYWORD_#{&1}", [token: &1]})

  @sub_operators %{
    AMPERSAND: :&,
    AMPERSANDEQUAL: :"&=",
    ASTERISK: :*,
    ASTERISK2: :**,
    ASTERISKEQUAL: :"*=",
    ASTERISKPERCENT: :"*%",
    ASTERISKPERCENTEQUAL: :"*%=",
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
    LARROWEQUAL: :<=,
    MINUS: :-,
    MINUSEQUAL: :"-=",
    MINUSPERCENT: :"-%",
    MINUSPERCENTEQUAL: :"-%=",
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

  @operators ~w(COMMA DOT DOT2 COLON LBRACE LBRACKET LPAREN MINUSRARROW LETTERC QUESTIONMARK RBRACE RBRACKET RPAREN SEMICOLON)a
  @operator_mapping Enum.map(@operators, &{&1, [token: true]})

  @collecteds ~w(IDENTIFIER INTEGER FLOAT INTEGER STRINGLITERAL BUILTINIDENTIFIER line_string)a
  @collected_mapping Enum.map(
                       @collecteds,
                       &{&1, [collect: true, post_traverse: {Collected, :post_traverse, [&1]}]}
                     )

  @parser_options [
                    container_doc_comment: [
                      tag: :doc_comment,
                      collect: true
                    ],
                    char_escape: [
                      post_traverse: :char_escape,
                      tag: true,
                      collect: true
                    ],
                    doc_comment: [post_traverse: :doc_comment, tag: true, collect: true],
                    line_comment: [post_traverse: :line_comment, tag: true, start_position: true],
                    AssignExpr: [
                      tag: AssignExpr,
                      post_traverse: {AssignExpr, :post_traverse, []}
                    ],
                    TestDecl: [
                      tag: TestDecl,
                      start_position: true,
                      post_traverse: {TestDecl, :post_traverse, []}
                    ],
                    skip: [ignore: true],
                    STRINGLITERALSINGLE: [
                      tag: true,
                      post_traverse: :string_literal_single,
                      collect: true
                    ],
                    Statement: [
                      tag: Statement,
                      start_position: true,
                      post_traverse: {Statement, :post_traverse, []}
                    ],
                    TopLevelComptime: [
                      tag: :toplevelcomptime,
                      post_traverse: {TopLevelComptime, :post_traverse, []}
                    ],
                    TopLevelDecl: [
                      tag: TopLevelDecl,
                      post_traverse: {TopLevelDecl, :post_traverse, []}
                    ],
                    TopLevelVar: [
                      tag: TopLevelVar,
                      start_position: true,
                      post_traverse: {TopLevelVar, :post_traverse, []}
                    ],
                    TopLevelFn: [
                      tag: TopLevelFn,
                      start_position: true,
                      post_traverse: {Function, :post_traverse, [TopLevelFn]}
                    ],
                    TypeExpr: [
                      tag: TypeExpr,
                      post_traverse: {TypeExpr, :post_traverse, []}
                    ],
                    Expr: [
                      tag: Expr,
                      post_traverse: {Expr, :post_traverse, []}
                    ],
                    InitList: [
                      tag: InitList,
                      post_traverse: {InitList, :post_traverse, []}
                    ],
                    Usingnamespace: [
                      tag: :usingnamespace,
                      post_traverse: {Usingnamespace, :post_traverse, []}
                    ],
                    ParamDeclList: [tag: true],
                    ParamDecl: [tag: ParamDecl, post_traverse: {ParamDecl, :post_traverse, []}],
                    PrimaryTypeExpr: [
                      tag: true,
                      post_traverse: {PrimaryTypeExpr, :post_traverse, []}
                    ],
                    IfStatement: [start_position: true],
                    AsmExpr: [tag: Asm, post_traverse: {Asm, :post_traverse, []}],
                    BlockExpr: [tag: BlockExpr, post_traverse: {BlockExpr, :post_traverse, []}],
                    Block: [tag: Block, post_traverse: {Block, :post_traverse, []}],
                    Root: [tag: true, post_traverse: :post_traverse]
                  ] ++
                    @keyword_mapping ++
                    @operator_mapping ++ @sub_operator_mapping ++ @collected_mapping

  Pegasus.parser_from_file(Path.join(__DIR__, "grammar/grammar.y"), @parser_options)

  zig_parser =
    empty()
    |> post_traverse(empty(), :init)
    |> parsec(:Root)

  defparsecp(:parser, zig_parser)

  def parse(string) do
    case parser(string) do
      {:ok, _, "", parser, _, _} ->
        %{
          parser
          | comments: Enum.reverse(parser.comments),
            dependencies: Enum.uniq(parser.dependencies)
        }
    end
  end

  # parser combinators

  defp init(code, args, context, _, _) do
    {code, args, struct(__MODULE__, context)}
  end

  defp doc_comment(rest, [{:doc_comment, [comment]} | rest_args], context, _, _) do
    {rest, [{:doc_comment, trim_doc_comment(comment, "///")} | rest_args], context}
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
    comment_data = {IO.iodata_to_binary(["//", comment]), position}
    {rest, rest_args, %{context | comments: [comment_data | context.comments]}}
  end

  defp char_escape(rest, [{:char_escape, [escape_string]} | rest_args], context, _, _) do
    {rest, [process_escape(escape_string) | rest_args], context}
  end

  defp trim_doc_comment(doc_comment, separator) do
    doc_comment
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.trim_leading(&1, separator))
    |> Enum.join("\n")
  end

  defp string_literal_single(rest, [{:STRINGLITERALSINGLE, [literal]} | rest_args], context, _, _) do
    trimmed_literal = String.trim(literal, ~S("))
    {rest, [trimmed_literal | rest_args], context}
  end

  def post_traverse("", [Root: [{:doc_comment, [doc_comment]} | code]], context, _, _) do
    doc_comment = trim_doc_comment(doc_comment, "//!")
    {"", [], struct(context, code: code, doc_comment: doc_comment)}
  end

  def post_traverse("", [Root: code], context, _, _) do
    {"", [], struct(context, code: code)}
  end

  @escaped %{?t => ?\t, ?n => ?\n, ?' => ?', ?" => ?", ?\\ => ?\\}
  defp process_escape(<<92, char>>), do: @escaped[char]

  defp process_escape("\\u{" <> what) do
    what
    |> String.trim_trailing("}")
    |> String.to_integer(16)
  end

  defp process_escape(<<"\\x"::binary, number::binary-2>>) do
    String.to_integer(number)
  end

  @doc false
  # maybe we take this out:

  def put_opt({identifier, options, params}, key, value) when is_map(options) do
    {identifier, %{options | key => value}, params}
  end

  def put_opt(other, _, _), do: other
end
