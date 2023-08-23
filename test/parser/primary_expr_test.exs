defmodule Zig.Parser.Test.PrimaryExprTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.StructLiteral

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
  #     / BlockLabel? LoopExpr # tested in loop_test.exs
  #     / Block
  #     / CurlySuffixExpr

  describe "break/continue expr" do
    # note these are a misuse of the const and are probably a semantic error.
    test "break" do
      assert [%{value: :break}] = Parser.parse("const foo = break;").code
    end

    test "break with tag" do
      assert [%{value: {:break, :foo}}] = Parser.parse("const foo = break :foo;").code
    end

    test "break with tag and value" do
      assert [%{value: {:break, :foo, :bar}}] = Parser.parse("const foo = break :foo bar;").code
    end

    test "continue" do
      assert [%{value: :continue}] =
               Parser.parse("const foo = continue;").code
    end

    test "continue with tag" do
      assert [%{value: {:continue, :foo}}] =
               Parser.parse("const foo = continue :foo;").code
    end
  end

  describe "tagged exprs" do
    test "comptime" do
      assert [%{value: {:comptime, :bar}}] = Parser.parse("const foo = comptime bar;").code
    end

    test "nosuspend" do
      assert [%{value: {:nosuspend, :bar}}] = Parser.parse("const foo = nosuspend bar;").code
    end

    test "resume" do
      assert [%{value: {:resume, :bar}}] = Parser.parse("const foo = resume bar;").code
    end

    test "return with no payload" do
      assert [%{value: :return}] = Parser.parse("const foo = return;").code
    end

    test "return with payload" do
      assert [%{value: {:return, :bar}}] = Parser.parse("const foo = return bar;").code
    end
  end

  describe "blocks" do
    # note this is probably a semantic error
    test "work" do
      assert [%{value: %Block{}}] = Parser.parse("const foo = {};").code
    end
  end

  describe "curly suffix init" do
    test "with an empty curly struct" do
      empty = %{}

      assert [%{value: %StructLiteral{type: :MyStruct, values: ^empty}}] =
               Parser.parse("const foo = MyStruct{};").code
    end

    test "gets location" do
      assert [_, %{value: %StructLiteral{location: {2, 13}}}] =
               Parser.parse(~S"""
               const bar = 1;
               const foo = MyStruct{};
               """).code
    end

    test "with a struct definer" do
      assert [%{value: %StructLiteral{type: :MyStruct, values: %{foo: {:integer, 1}}}}] =
               Parser.parse("const foo = MyStruct{.foo = 1};").code
    end

    test "with a struct definer with two terms" do
      assert [
               %{
                 value: %StructLiteral{
                   type: :MyStruct,
                   values: %{foo: {:integer, 1}, bar: {:integer, 2}}
                 }
               }
             ] =
               Parser.parse("const foo = MyStruct{.foo = 1, .bar = 2};").code
    end

    test "with an anonymous definer with two terms" do
      assert [%{value: %StructLiteral{type: nil, values: %{foo: {:integer, 1}}}}] =
               Parser.parse("const foo = .{.foo = 1};").code
    end

    test "with an array definer" do
      assert [
               %{
                 value: %StructLiteral{
                   type: :MyArrayType,
                   values: %{0 => {:integer, 1}, 1 => {:integer, 2}, 2 => {:integer, 3}}
                 }
               }
             ] =
               Parser.parse("const foo = MyArrayType{1, 2, 3};").code
    end

    test "as a tuple" do
      assert [
               %{
                 value: %StructLiteral{
                   type: nil,
                   values: %{0 => {:integer, 1}, 1 => {:integer, 2}, 2 => {:integer, 3}}
                 }
               }
             ] =
               Parser.parse("const foo = .{1, 2, 3};").code
    end
  end
end
