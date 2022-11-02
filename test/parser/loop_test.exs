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

      assert {:for, :array, :item, %Block{code: []}} = forloop
    end

    test "modifying for loop" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = for (array) |*item| {};")

      assert {:for, :array, {:ptr, :item}, %Block{code: []}} = forloop
    end

    test "basic for loop with index" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = for (array) |item, index| {};")

      assert {:for, :array, {:item, :index}, %Block{code: []}} = forloop
    end

    test "modifiable for loop with index" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = for (array) |*item, index| {};")

      assert {:for, :array, {{:ptr, :item}, :index}, %Block{code: []}} = forloop
    end

    test "for loop with else" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = for (array) |item| {} else {};")

      assert {:for, :array, :item, %Block{code: []}, %Block{code: []}} = forloop
    end

    test "inline for loop" do
      assert %Parser{decls: [%Const{value: forloop}]} =
               Parser.parse("const foo = inline for (array) |item| {};")

      assert {:inline_for, :array, :item, %Block{code: []}} = forloop
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

      assert {:while, :condition, %Block{code: []}} = whileloop
    end

    test "while loop with payload" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) |value| {};")

      assert {:while, :condition, {:payload, :value, %Block{code: []}}} = whileloop
    end

    test "while loop with pointer payload" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) |*value| {};")

      assert {:while, :condition, {:ptr_payload, :value, %Block{code: []}}} = whileloop
    end

    test "while loop with continuation" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) : (next) {};")

      assert {:while, {:condition, :next}, %Block{code: []}} = whileloop
    end

    test "while loop with else" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) {} else {};")

      assert {:while, :condition, %Block{code: []}, %Block{code: []}} = whileloop
    end

    test "while loop with else and payload" do
      assert %Parser{decls: [%Const{value: whileloop}]} =
               Parser.parse("const foo = while (condition) {} else |err| {};")

      assert {:while, :condition, %Block{code: []}, {:payload, :err, %Block{code: []}}} =
               whileloop
    end
  end
end
