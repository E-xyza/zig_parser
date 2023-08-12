defmodule Zig.Parser.Test.PrimaryExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  # tests:
  # PrimaryExpr
  #    <- AsmExpr  # tested in asm_test.exs
  #     / IfExpr  # tested in if_expr_test.exs
  #     / KEYWORD_break BreakLabel? Expr?
  #     / KEYWORD_comptime Expr
  #     / KEYWORD_nosuspend Expr
  #     / KEYWORD_continue BreakLabel?
  #     / KEYWORD_resume Expr
  #     / KEYWORD_return Expr?
  #     / BlockLabel? LoopExpr # <-- punted to LoopTest
  #     / Block
  #     / CurlySuffixExpr

  describe "break/continue expr" do
    # note these are a misuse of the const and are probably a semantic error.
    test "break" do
      assert const_with(:break) = Parser.parse("const foo = break;").code
    end

    test "break with tag" do
      assert const_with({:break, :foo}) = Parser.parse("const foo = break :foo;").code
    end

    test "break with tag and value" do
      assert const_with({:break, :foo, :bar}) = Parser.parse("const foo = break :foo bar;").code
    end

    test "continue" do
      assert const_with(:continue) = Parser.parse("const foo = continue;").code
    end

    test "continue with tag" do
      assert const_with({:continue, :foo}) = Parser.parse("const foo = continue :foo;").code
    end
  end

  describe "tagged exprs" do
    test "comptime" do
      assert const_with({:comptime, :bar}) = Parser.parse("const foo = comptime bar;").code
    end

    test "nosuspend" do
      assert const_with({:nosuspend, :bar}) = Parser.parse("const foo = nosuspend bar;").code
    end

    test "resume" do
      assert const_with({:resume, :bar}) = Parser.parse("const foo = resume bar;").code
    end

    test "return" do
      assert const_with({:return, :bar}) = Parser.parse("const foo = return bar;").code
    end
  end

  describe "blocks" do
    # note this is probably a semantic error
    test "work" do
      assert const_with({:block, _, []}) = Parser.parse("const foo = {};").code
    end
  end

  describe "curly suffix init" do
    test "with an empty curly struct" do
      assert const_with({:empty, :MyStruct}) = Parser.parse("const foo = MyStruct{};").code
    end

    test "with a struct definer" do
      assert const_with({:struct, :MyStruct, %{foo: {:integer, 1}}}) =
               Parser.parse("const foo = MyStruct{.foo = 1};").code
    end

    test "with a struct definer with two terms" do
      assert const_with({:struct, :MyStruct, %{foo: {:integer, 1}, bar: {:integer, 2}}}) =
               Parser.parse("const foo = MyStruct{.foo = 1, .bar = 2};").code
    end

    test "with an array definer" do
      assert const_with({:array, :MyArrayType, [integer: 1, integer: 2, integer: 3]}) =
               Parser.parse("const foo = MyArrayType{1, 2, 3};").code
    end
  end
end
