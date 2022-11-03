defmodule Zig.Parser.Test.LoopTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.Const

  # tests:
  # PrimaryExpr
  #    <- AsmExpr
  #     / BlockLabel? LoopExpr

  describe "for loops" do
    # tests:
    # ForExpr <- ForPrefix Expr (KEYWORD_else Expr)?
    # ForPrefix <- KEYWORD_for LPAREN Expr RPAREN PtrIndexPayload

    test "basic for loop" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = for (array) |item| {};")

      assert {:for, :array, :item, {:block, _, []}} = forloop
    end

    test "modifying for loop" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = for (array) |*item| {};")

      assert {:for, :array, {:ptr, :item}, {:block, _, []}} = forloop
    end

    test "basic for loop with index" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = for (array) |item, index| {};")

      assert {:for, :array, {:item, :index}, {:block, _, []}} = forloop
    end

    test "modifiable for loop with index" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = for (array) |*item, index| {};")

      assert {:for, :array, {{:ptr, :item}, :index}, {:block, _, []}} = forloop
    end

    test "for loop with else" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = for (array) |item| {} else {};")

      assert {:for, :array, :item, {:block, _, []}, {:block, _, []}} = forloop
    end

    test "inline for loop" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = inline for (array) |item| {};")

      assert {:inline_for, :array, :item, {:block, _, []}} = forloop
    end
  end

  describe "while loops" do
    # tests:
    # WhileExpr <- WhilePrefix Expr (KEYWORD_else Payload? Expr)?
    # WhilePrefix <- KEYWORD_while LPAREN Expr RPAREN PtrPayload? WhileContinueExpr?
    # WhileContinueExpr <- COLON LPAREN AssignExpr RPAREN

    test "basic while loop" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) {};")

      assert {:while, :condition, {:block, _, []}} = whileloop
    end

    test "while loop with payload" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) |value| {};")

      assert {:while, :condition, {:payload, :value, {:block, _, []}}} = whileloop
    end

    test "while loop with pointer payload" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) |*value| {};")

      assert {:while, :condition, {:ptr_payload, :value, {:block, _, []}}} = whileloop
    end

    test "while loop with continuation" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) : (next) {};")

      assert {:while, {:condition, :next}, {:block, _, []}} = whileloop
    end

    test "while loop with else" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) {} else {};")

      assert {:while, :condition, {:block, _, []}, {:block, _, []}} = whileloop
    end

    test "while loop with else and payload" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) {} else |err| {};")

      assert {:while, :condition, {:block, _, []}, {:payload, :err, {:block, _, []}}} =
               whileloop
    end
  end
end
