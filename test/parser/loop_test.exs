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
      assert %Parser{decls: [{:const, _, {_, _, forloop}}]} =
               Parser.parse("const foo = for (array) |item| {};")

      assert {:for, %{label: nil, inline: false},
              enum: :array, payload: :item, do: {:block, _, []}} = forloop
    end

    test "modifying for loop" do
      assert %Parser{decls: [{:const, _, {_, _, forloop}}]} =
               Parser.parse("const foo = for (array) |*item| {};")

      assert {:for, _, enum: :array, ptr_payload: :item, do: {:block, _, []}} = forloop
    end

    test "basic for loop with index" do
      assert %Parser{decls: [{:const, _, {_, _, forloop}}]} =
               Parser.parse("const foo = for (array) |item, index| {};")

      assert {:for, _, enum: :array, payload: :item, index: :index, do: {:block, _, []}} = forloop
    end

    test "modifiable for loop with index" do
      assert %Parser{decls: [{:const, _, {_, _, forloop}}]} =
               Parser.parse("const foo = for (array) |*item, index| {};")

      assert {:for, _, enum: :array, ptr_payload: :item, index: :index, do: {:block, _, []}} =
               forloop
    end

    test "for loop with else" do
      assert %Parser{decls: [{:const, _, {_, _, forloop}}]} =
               Parser.parse("const foo = for (array) |item| {} else {};")

      assert {:for, _, enum: :array, payload: :item, do: {:block, _, []}, else: {:block, _, []}} =
               forloop
    end

    test "inline for loop" do
      assert %Parser{decls: [{:const, _, {_, _, forloop}}]} =
               Parser.parse("const foo = inline for (array) |item| {};")

      assert {:for, %{inline: true}, enum: :array, payload: :item, do: {:block, _, []}} = forloop
    end
  end

  describe "while loops" do
    # tests:
    # WhileExpr <- WhilePrefix Expr (KEYWORD_else Payload? Expr)?
    # WhilePrefix <- KEYWORD_while LPAREN Expr RPAREN PtrPayload? WhileContinueExpr?
    # WhileContinueExpr <- COLON LPAREN AssignExpr RPAREN

    test "basic while loop" do
      assert %Parser{decls: [{:const, _, {_, _, whileloop}}]} =
               Parser.parse("const foo = while (condition) {};")

      assert {:while, _, condition: :condition, do: {:block, _, []}} = whileloop
    end

    test "while loop with payload" do
      assert %Parser{decls: [{:const, _, {_, _, whileloop}}]} =
               Parser.parse("const foo = while (condition) |value| {};")

      assert {:while, _, condition: :condition, payload: :value, do: {:block, _, []}} = whileloop
    end

    test "while loop with pointer payload" do
      assert %Parser{decls: [{:const, _, {_, _, whileloop}}]} =
               Parser.parse("const foo = while (condition) |*value| {};")

      assert {:while, _, condition: :condition, ptr_payload: :value, do: {:block, _, []}} =
               whileloop
    end

    test "while loop with continuation" do
      assert %Parser{decls: [{:const, _, {_, _, whileloop}}]} =
               Parser.parse("const foo = while (condition) : (next) {};")

      assert {:while, _, condition: :condition, next: :next, do: {:block, _, []}} = whileloop
    end

    test "while loop with else" do
      assert %Parser{decls: [{:const, _, {_, _, whileloop}}]} =
               Parser.parse("const foo = while (condition) {} else {};")

      assert {:while, _, condition: :condition, do: {:block, _, []}, else: {:block, _, []}} =
               whileloop
    end

    test "while loop with else and payload" do
      assert %Parser{decls: [{:const, _, {_, _, whileloop}}]} =
               Parser.parse("const foo = while (condition) {} else |err| {};")

      assert {:while, _,
              condition: :condition,
              do: {:block, _, []},
              else_payload: :err,
              else: {:block, _, []}} = whileloop
    end
  end
end
