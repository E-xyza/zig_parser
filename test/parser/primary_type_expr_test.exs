defmodule Zig.Parser.Test.PrimaryTypeExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  alias Zig.Parser
  alias Zig.Parser.Const

  # TESTS:
  #
  # PrimaryTypeExpr
  # <- BUILTINIDENTIFIER FnCallArguments
  #  / CHAR_LITERAL
  #  / ContainerDecl
  #  / DOT IDENTIFIER
  #  / DOT InitList
  #  / ErrorSetDecl
  #  / FLOAT
  #  / FnProto
  #  / GroupedExpr
  #  / LabeledTypeExpr
  #  / IDENTIFIER
  #  / IfTypeExpr
  #  / INTEGER
  #  / KEYWORD_comptime TypeExpr
  #  / KEYWORD_error DOT IDENTIFIER
  #  / KEYWORD_anyframe
  #  / KEYWORD_unreachable
  #  / STRINGLITERAL
  #  / SwitchExpr

  describe "builtin function" do
    test "with no arguments" do
      assert %Parser{decls: [%Const{value: expr}]} = Parser.parse("const foo = @builtin_fn();")
      assert {:builtin, :builtin_fn, []} = expr
    end

    test "with one arguments" do
      assert %Parser{decls: [%Const{value: expr}]} = Parser.parse("const foo = @builtin_fn(foo);")
      assert {:builtin, :builtin_fn, [:foo]} = expr
    end

    test "with two arguments" do
      assert %Parser{decls: [%Const{value: expr}]} =
               Parser.parse("const foo = @builtin_fn(foo, bar);")

      assert {:builtin, :builtin_fn, [:foo, :bar]} = expr
    end
  end

  describe "char literal" do
    test "basic ascii" do
      assert %Parser{decls: [%Const{value: ?a}]} = Parser.parse("const foo = 'a';")
    end

    @tag :skip
    test "utf-8 literal" do
      assert %Parser{decls: [%Const{value: ?🚀}]} = Parser.parse("const foo = '🚀';")
    end

    test "escaped char" do
      assert %Parser{decls: [%Const{value: ?\t}]} = Parser.parse("const foo = '\\t';")
    end

    test "escaped hex" do
      assert %Parser{decls: [%Const{value: ?🚀}]} =
               Parser.parse("const foo = '\\u{1F680}';")
    end
  end

  describe "container decl" do
    test "container decl"
  end
end
