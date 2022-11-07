defmodule Zig.Parser.Test.PrimaryTypeExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  alias Zig.Parser

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
      assert [{:const, _, {_, _, expr}}] = Parser.parse("const foo = @builtin_fn();").code

      assert {:builtin, :builtin_fn, []} = expr
    end

    test "with one arguments" do
      assert [{:const, _, {_, _, expr}}] = Parser.parse("const foo = @builtin_fn(foo);").code

      assert {:builtin, :builtin_fn, [:foo]} = expr
    end

    test "with two arguments" do
      assert [{:const, _, {_, _, expr}}] = Parser.parse("const foo = @builtin_fn(foo, bar);").code

      assert {:builtin, :builtin_fn, [:foo, :bar]} = expr
    end
  end

  describe "char literal" do
    test "basic ascii" do
      assert [{:const, _, {_, _, ?a}}] = Parser.parse("const foo = 'a';").code
    end

    @tag :skip
    test "utf-8 literal" do
      assert [{:const, _, {_, _, ?🚀}}] = Parser.parse("const foo = '🚀';").code
    end

    test "escaped char" do
      assert [{:const, _, {_, _, ?\t}}] = Parser.parse("const foo = '\\t';").code
    end

    test "escaped hex" do
      assert [{:const, _, {_, _, ?🚀}}] = Parser.parse("const foo = '\\u{1F680}';").code
    end
  end

  describe "container decl" do
    test "container decl"
  end
end
