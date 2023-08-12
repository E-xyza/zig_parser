defmodule Zig.Parser.Test.IfExprtest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.If

  describe "if expr" do
    # IfExpr <- IfPrefix Expr (KEYWORD_else Payload? Expr)?
    # IfPrefix <- KEYWORD_if LPAREN Expr RPAREN PtrPayload?

    test "basic if statement only" do
      assert [%{value: %If{test: :foo, then: :bar}}] =
               Parser.parse("const foo = if (foo) bar;").code
    end

    test "basic if statement with payload paramater" do
      assert [%{value: %If{test: :foo, ptr_payload: :bar, then: :bar}}] =
               Parser.parse("const foo = if (foo) |bar| bar;").code
    end

    test "basic if statement with pointer payload parameter" do
      assert [%{value: %If{test: :foo, ptr_payload: {:*, :bar}, then: :bar}}] =
               Parser.parse("const foo = if (foo) |*bar| bar;").code
    end

    test "basic else statement" do
      assert [%{value: %If{test: :foo, then: :bar, else: :baz}}] =
               Parser.parse("const foo = if (foo) bar else baz;").code
    end

    test "else statement with payload" do
      assert [%{value: %If{test: :foo, then: :bar, else_payload: :baz, else: :baz}}] =
               Parser.parse("const foo = if (foo) bar else |baz| baz;").code
    end
  end
end
