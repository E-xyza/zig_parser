defmodule Zig.Parser.Test.StatementTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.Const
  alias Zig.Parser.Var

  #
  # TESTS:
  # Statement
  #   <- KEYWORD_comptime? VarDecl
  #    / KEYWORD_comptime BlockExprStatement
  #    / KEYWORD_nosuspend BlockExprStatement
  #    / KEYWORD_suspend BlockExprStatement
  #    / KEYWORD_defer BlockExprStatement
  #    / KEYWORD_errdefer Payload? BlockExprStatement
  #    / IfStatement
  #    / LabeledStatement
  #    / SwitchExpr
  #    / AssignExpr SEMICOLON

  describe "var declarations" do
    test "can be runtime" do
      assert [%{code: [%Var{name: x, value: {:integer, 1}}]}] =
               Parser.parse("comptime {var x = 1;}").code
    end

    test "can be comptime" do
      [%{code: [%Var{comptime: true}]}] = Parser.parse("comptime {comptime var x = 1;}").code
    end
  end

  describe "const declarations" do
    test "can be runtime" do
      assert [%{code: [%Const{name: x, value: {:integer, 1}}]}] =
               Parser.parse("comptime {const x = 1;}").code
    end

    test "can be comptime" do
      [%{code: [%Const{comptime: true}]}] = Parser.parse("comptime {comptime const x = 1;}").code
    end
  end

  describe "comptime declarations" do
    test "can apply to a block" do
      [%{code: [%Block{comptime: true}]}] = Parser.parse("comptime {comptime {}}").code
    end

    test "can apply to a generic call" do
      [%{code: [%Block{comptime: true}]}] = Parser.parse("comptime {comptime foo(bar);}").code
    end

    #
    #   test "can be nosuspend" do
    #     toplevelblockcontent(nosuspend) = Parser.parse("comptime {nosuspend {}}").code
    #     assert {:nosuspend, _, {:block, _, []}} = nosuspend
    #   end
    #
    #   test "can be suspend" do
    #     toplevelblockcontent(suspend) = Parser.parse("comptime {suspend {}}").code
    #     assert {:suspend, _, {:block, _, []}} = suspend
    #   end
    #
    #   test "can be defer" do
    #     toplevelblockcontent(defer) = Parser.parse("comptime {defer {}}").code
    #     assert {:defer, _, {:block, _, []}} = defer
    #   end
    #
    #   test "can be errdefer" do
    #     toplevelblockcontent(errdefer) = Parser.parse("comptime {errdefer {}}").code
    #     assert {:errdefer, _, do: {:block, _, []}} = errdefer
    #   end
    #
    #   test "can be errdefer with a payload" do
    #     toplevelblockcontent(errdefer) = Parser.parse("comptime {errdefer |err| {}}").code
    #     assert {:errdefer, _, payload: :err, do: {:block, _, []}} = errdefer
    #   end
    # end
    #
    # describe "prefixed expressions" do
    #   test "can be comptime" do
    #     toplevelblockcontent(ifast) = Parser.parse("comptime {comptime if (x) y;}").code
    #     assert {:comptime, _, {:if, _, _}} = ifast
    #   end
    #
    #   test "can be nosuspend" do
    #     toplevelblockcontent(ifast) = Parser.parse("comptime {nosuspend if (x) y;}").code
    #     assert {:nosuspend, _, {:if, _, _}} = ifast
    #   end
    #
    #   test "can be suspend" do
    #     toplevelblockcontent(ifast) = Parser.parse("comptime {suspend if (x) y;}").code
    #     assert {:suspend, _, {:if, _, _}} = ifast
    #   end
    #
    #   test "can be defer" do
    #     toplevelblockcontent(ifast) = Parser.parse("comptime {defer if (x) y;}").code
    #     assert {:defer, _, {:if, _, _}} = ifast
    #   end
    #
    #   test "can be errdefer" do
    #     toplevelblockcontent(ifast) = Parser.parse("comptime {errdefer if (x) y;}").code
    #     assert {:errdefer, _, do: {:if, _, _}} = ifast
    #   end
    #
    #   test "can be errdefer with payload" do
    #     toplevelblockcontent(ifast) = Parser.parse("comptime {errdefer |err| if (x) y;}").code
    #     assert {:errdefer, _, payload: :err, do: {:if, _, _}} = ifast
    #   end
    # end
    #
    # describe "statement can be if" do
    #   test "with basic" do
    #     toplevelblockcontent(ifast) = Parser.parse("comptime {if (x) y;}").code
    #     assert {:if, _, [condition: :x, consequence: :y]} = ifast
    #   end
    #
    #   test "with payload" do
    #     toplevelblockcontent(ifast) = Parser.parse("comptime {if (x) |arg| y;}").code
    #     assert {:if, _, [condition: :x, payload: :arg, consequence: :y]} = ifast
    #   end
    #
    #   test "with pointer payload" do
    #     toplevelblockcontent(ifast) = Parser.parse("comptime {if (x) |*arg| y;}").code
    #     assert {:if, _, [condition: :x, ptr_payload: :arg, consequence: :y]} = ifast
    #   end
    #
    #   test "with else" do
    #     toplevelblockcontent(ifast) = Parser.parse("comptime {if (x) y else z; }").code
    #     assert {:if, _, [condition: :x, consequence: :y, else: :z]} = ifast
    #   end
    # end
    #
    # describe "statement can be for" do
    #   test "basic" do
    #     toplevelblockcontent(forast) = Parser.parse("comptime {for (x) |value| {}}").code
    #     assert {:for, _, [enum: :x, payload: :value, do: {:block, _, _}]} = forast
    #   end
    #
    #   test "with label" do
    #     toplevelblockcontent(forast) = Parser.parse("comptime {loop: for (x) |value| {}}").code
    #     assert {:for, %{label: :loop}, _} = forast
    #   end
    #
    #   test "with inline" do
    #     toplevelblockcontent(forast) = Parser.parse("comptime {inline for (x) |value| {}}").code
    #     assert {:for, %{inline: true}, _} = forast
    #   end
    #
    #   test "with label and inline" do
    #     toplevelblockcontent(forast) =
    #       Parser.parse("comptime {loop: inline for (x) |value| {}}").code
    #
    #     assert {:for, %{inline: true, label: :loop}, _} = forast
    #   end
    #
    #   test "with a single statement" do
    #     toplevelblockcontent(forast) = Parser.parse("comptime {for (x) |value| this;}").code
    #     assert {:for, _, [enum: :x, payload: :value, do: :this]} = forast
    #   end
    # end
    #
    # describe "statement can be while" do
    #   test "basic" do
    #     toplevelblockcontent(whileast) = Parser.parse("comptime {while (x) {}}").code
    #     assert {:while, %{label: nil, inline: false}, condition: :x, do: {:block, _, []}} = whileast
    #   end
    #
    #   test "with label" do
    #     toplevelblockcontent(whileast) = Parser.parse("comptime {loop: while (x) {}}").code
    #     assert {:while, %{label: :loop}, condition: :x, do: {:block, _, []}} = whileast
    #   end
    #
    #   test "with inline" do
    #     toplevelblockcontent(whileast) = Parser.parse("comptime {inline while (x) {}}").code
    #     assert {:while, %{inline: true}, condition: :x, do: {:block, _, []}} = whileast
    #   end
    #
    #   test "with label and inline" do
    #     toplevelblockcontent(whileast) = Parser.parse("comptime {loop: inline while (x) {}}").code
    #
    #     assert {:while, %{inline: true, label: :loop}, condition: :x, do: {:block, _, []}} =
    #              whileast
    #   end
    #
    #   test "with a single statement" do
    #     toplevelblockcontent(whileast) = Parser.parse("comptime {while (x) this;}").code
    #     assert {:while, _, condition: :x, do: :this} = whileast
    #   end
    # end
    #
    # describe "statement can be switch" do
    #   test "basic" do
    #     toplevelblockcontent(switchast) = Parser.parse("comptime {switch (expr) {}}").code
    #     assert {:switch, _, [condition: :expr, switches: []]} = switchast
    #   end
    #
    #   test "with one prong" do
    #     toplevelblockcontent(switchast) = Parser.parse("comptime {switch (expr) {a => b}}").code
    #     assert {:switch, _, [condition: :expr, switches: [a: :b]]} = switchast
    #   end
    #
    #   test "with else" do
    #     toplevelblockcontent(switchast) = Parser.parse("comptime {switch (expr) {
    #               a => b,
    #              else => c}}").code
    #
    #     assert {:switch, _, [condition: :expr, switches: [a: :b, else: :c]]} = switchast
    #   end
    # end
    #
    # describe "statement can be assign expression" do
    #   # AssignOp
    #   # <- ASTERISKEQUAL
    #   #  / SLASHEQUAL
    #   #  / PERCENTEQUAL
    #   #  / PLUSEQUAL
    #   #  / MINUSEQUAL
    #   #  / LARROW2EQUAL
    #   #  / RARROW2EQUAL
    #   #  / AMPERSANDEQUAL
    #   #  / CARETEQUAL
    #   #  / PIPEEQUAL
    #   #  / ASTERISKPERCENTEQUAL
    #   #  / PLUSPERCENTEQUAL
    #   #  / MINUSPERCENTEQUAL
    #   #  / EQUAL
    #
    #   test "ASTERISKEQUAL => *=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a *= b;}").code
    #     assert {:"*=", _, [:a, :b]} = opast
    #   end
    #
    #   test "SLASHEQUAL => /=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a /= b;}").code
    #     assert {:"/=", _, [:a, :b]} = opast
    #   end
    #
    #   test "PERCENTEQUAL => %=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a %= b;}").code
    #     assert {:"%=", _, [:a, :b]} = opast
    #   end
    #
    #   test "PLUSEQUAL => +=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a += b;}").code
    #     assert {:"+=", _, [:a, :b]} = opast
    #   end
    #
    #   test "MINUSEQUAL => -=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a -= b;}").code
    #     assert {:"-=", _, [:a, :b]} = opast
    #   end
    #
    #   test "LARROW2EQUAL => <<=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a <<= b;}").code
    #     assert {:"<<=", _, [:a, :b]} = opast
    #   end
    #
    #   test "RARROW2SEQUAL => >>=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a >>= b;}").code
    #     assert {:">>=", _, [:a, :b]} = opast
    #   end
    #
    #   test "AMPERSANDEQUAL => &=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a &= b;}").code
    #     assert {:"&=", _, [:a, :b]} = opast
    #   end
    #
    #   test "CARETEQUAL => ^=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a ^= b;}").code
    #     assert {:"^=", _, [:a, :b]} = opast
    #   end
    #
    #   test "PIPEEQUAL => |=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a |= b;}").code
    #     assert {:"|=", _, [:a, :b]} = opast
    #   end
    #
    #   test "ASTERISKPERCENTEQUAL => *%=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a *%= b;}").code
    #     assert {:"*%=", _, [:a, :b]} = opast
    #   end
    #
    #   test "PLUSPERCENTEQUAL => +%=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a +%= b;}").code
    #     assert {:"+%=", _, [:a, :b]} = opast
    #   end
    #
    #   test "MINUSPERCENTEQUAL => -%=" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a -%= b;}").code
    #     assert {:"-%=", _, [:a, :b]} = opast
    #   end
    #
    #   test "EQUAL => =" do
    #     toplevelblockcontent(opast) = Parser.parse("comptime {a = b;}").code
    #     assert {:=, _, [:a, :b]} = opast
    #   end
  end
end
