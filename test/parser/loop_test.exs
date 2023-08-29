defmodule Zig.Parser.Test.LoopTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.For
  alias Zig.Parser.While

  # tests:
  # PrimaryExpr
  #    <- AsmExpr
  #     / BlockLabel? LoopExpr

  describe "for loops" do
    # tests:
    # ForExpr <- ForPrefix Expr (KEYWORD_else Expr)?
    # ForPrefix <-KEYWORD_for LPAREN ForArgumentsList RPAREN PtrListPayload
    # ForArgumentsList <- ForItem (COMMA ForItem)* COMMA?
    # ForItem <- Expr (DOT2 Expr?)?
    # PtrListPayload <- PIPE ASTERISK? IDENTIFIER (COMMA ASTERISK? IDENTIFIER)* COMMA? PIPE

    test "basic for loop" do
      assert [%{value: %For{iterators: [:array], captures: [:item], block: %Block{}}}] =
               Parser.parse("const foo = for (array) |item| {};").code
    end

    test "gets location" do
      assert [_, %{value: %For{location: {2, 13}}}] =
               Parser.parse(~S"""
               const bar = 1;
               const foo = for (array) |item| {};
               """).code
    end

    test "modifying for loop" do
      assert [%{value: %For{iterators: [:array], captures: [{:*, :item}]}}] =
               Parser.parse("const foo = for (array) |*item| {};").code
    end

    test "basic for loop with index" do
      assert [
               %{
                 value: %For{
                   iterators: [:array, {:.., {:integer, 0}}],
                   captures: [:item, :index]
                 }
               }
             ] =
               Parser.parse("const foo = for (array, 0..) |item, index| {};").code
    end

    test "basic for loop with limited range" do
      assert [
               %{
                 value: %For{
                   iterators: [:array, {:.., {:integer, 0}, {:integer, 10}}],
                   captures: [:item, :index]
                 }
               }
             ] =
               Parser.parse("const foo = for (array, 0..10) |item, index| {};").code
    end

    test "for loop with else" do
      assert [%{value: %For{else: %Block{}}}] =
               Parser.parse("const foo = for (array) |item| {} else {};").code
    end

    test "inline for loop" do
      assert [%{block: %{code: [%For{inline: true}]}}] =
               Parser.parse("""
               fn my_func() void {
                 inline for (array) |item| { }
               }
               """).code
    end

    test "tagged for loop" do
      assert [%{value: %For{label: :tag}}] =
               Parser.parse("const foo = tag: for (array) | item | {};").code
    end

    test "for loop with short capture" do
      assert [%{value: %For{block: {:try, _}}}] = Parser.parse("const foo = for (buf[4]) |elem| try expect(elem == 0);").code
    end
  end

  describe "while loops" do
    # tests:
    # WhileExpr <- WhilePrefix Expr (KEYWORD_else Payload? Expr)?
    # WhilePrefix <- KEYWORD_while LPAREN Expr RPAREN PtrPayload? WhileContinueExpr?
    # WhileContinueExpr <- COLON LPAREN AssignExpr RPAREN

    test "basic while loop" do
      assert [%{value: %While{condition: :condition}}] =
               Parser.parse("const foo = while (condition) {};").code
    end

    test "get location" do
      assert [_, %{value: %While{location: {2, 13}}}] =
               Parser.parse(~S"""
               const bar = 1;
               const foo = while (condition) {};
               """).code
    end

    test "while loop with payload" do
      assert [%{value: %While{payload: :value}}] =
               Parser.parse("const foo = while (condition) |value| {};").code
    end

    test "while loop with pointer payload" do
      assert [%{value: %While{payload: {:*, :value}}}] =
               Parser.parse("const foo = while (condition) |*value| {};").code
    end

    test "while loop with continuation" do
      assert [%{value: %While{condition: :condition, continue: :next}}] =
               Parser.parse("const foo = while (condition) : (next) {};").code
    end

    test "while loop with else" do
      assert [%{value: %While{else: %Block{}}}] =
               Parser.parse("const foo = while (condition) {} else {};").code
    end

    test "while loop with else and payload" do
      assert [%{value: %While{else_payload: :err}}] =
               Parser.parse("const foo = while (condition) {} else |err| {};").code
    end

    test "non-statement while loop" do
      assert [%{value: %{code: [%While{}]}}] =
               Parser.parse("const foo = comptime {while (condition) {}};").code
    end
  end
end
