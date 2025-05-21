defmodule Zig.Parser.Test.SwitchTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Switch

  describe "switch expr" do
    # SwitchExpr <- KEYWORD_switch LPAREN Expr RPAREN LBRACE SwitchProngList RBRACE
    test "basic switch statement only" do
      assert [%{value: %Switch{subject: :foo, prongs: []}}] =
               Parser.parse("const foo = switch (foo) {};").code
    end

    test "one prong" do
      assert [%{value: %Switch{prongs: prongs}}] =
               Parser.parse("const foo = switch (foo) {1 => .foo};").code

      assert [{[integer: 1], {:enum_literal, :foo}}] = prongs
    end

    test "two prongs" do
      assert [%{value: %Switch{prongs: prongs}}] =
               Parser.parse("const foo = switch (foo) {1 => .foo, 2 => .bar};").code

      assert [{[integer: 1], {:enum_literal, :foo}}, {[integer: 2], {:enum_literal, :bar}}] =
               prongs
    end

    test "range in prong" do
      assert [%{value: %Switch{prongs: prongs}}] =
               Parser.parse("const foo = switch (foo) {1...2 => .foo};").code

      assert [{[{:range, {:integer, 1}, {:integer, 2}}], {:enum_literal, :foo}}] =
               prongs
    end

    test "two items in prong" do
      assert [%{value: %Switch{prongs: prongs}}] =
               Parser.parse("const foo = switch (foo) {1, 2 => .foo};").code

      assert [{[{:integer, 1}, {:integer, 2}], {:enum_literal, :foo}}] =
               prongs
    end

    test "with inline" do
      assert [%{value: %Switch{prongs: prongs}}] =
               Parser.parse("const foo = switch (foo) {inline 1 => .foo};").code

      assert [{{:inline, [integer: 1]}, {:enum_literal, :foo}}] =
               prongs
    end

    test "with capture" do
      assert [%{value: %Switch{prongs: prongs}}] =
               Parser.parse("const foo = switch (foo) {1 => |bar| .foo};").code

      assert [{[integer: 1], :bar, {:enum_literal, :foo}}] = prongs
    end

    test "with capture and more" do
      assert [%{value: %Switch{prongs: prongs}}] =
               Parser.parse("const foo = switch (foo) {1 => |bar| .foo, 2 => .baz};").code

      assert [{[integer: 1], :bar, {:enum_literal, :foo}}, {[integer: 2], {:enum_literal, :baz}}] =
               prongs
    end

    test "optional comma" do
      assert [%{value: %Switch{prongs: prongs}}] =
               Parser.parse("const foo = switch (foo) {1 => .foo,};").code

      assert [{[integer: 1], {:enum_literal, :foo}}] = prongs
    end

    test "optional comma in prong" do
      assert [%{value: %Switch{prongs: prongs}}] =
               Parser.parse("const foo = switch (foo) {1, => .foo};").code

      assert [{[integer: 1], {:enum_literal, :foo}}] = prongs
    end

    test "can be a dereferenced expr" do
      assert [%{value: {:call, {:ref, [switch, :baz]}, []}}] =
               Parser.parse("""
               const foo = switch (bar) {
               }.baz();
               """).code

      assert %Switch{prongs: [], subject: :bar} = switch
    end
  end

  describe "labelled switch" do
    test "works" do
      assert [%{value: %Switch{label: :s}}] = Parser.parse("const val = s: switch (six) {};").code
    end

    test "labelled continue" do
      assert [%{value: %Switch{prongs: [{[integer: 1], {:continue, :s, _}}], label: :s}}] =
               Parser.parse("""
               const result = s: switch (@as(u32, 1)) {
                       1 => continue :s 123,
               };
               """).code
    end

    test "labelled switch that is a loop." do
      assert [%{block: %{code: [%Switch{label: :eval}]}}] =
               Parser.parse("""
               fn doTheTest() !void {
                   eval: switch (val) {}
               }
               """).code
    end
  end
end
