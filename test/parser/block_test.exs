defmodule Zig.Parser.Test.BlockTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.Const

  # note that for these tests we're testing blocks in two cases:
  # - comptime block and function block, for simplicity.

  describe "general properties of a comptime block" do
    test "can be empty" do
      assert [%Block{code: []}] = Parser.parse("comptime {}").code
    end

    test "location is set" do
      assert [%Block{location: {1, 10}}] = Parser.parse("comptime {}").code
    end

    test "can have a label" do
      assert [%Const{value: %Block{label: :foo}}] =
               Parser.parse("const a = comptime foo: {};").code
    end

    test "can have one statement" do
      assert [%Block{code: [%Const{}]}] =
               Parser.parse("comptime { const a = 1; }").code
    end

    test "can have multiple statements" do
      assert [%Block{code: [%Const{}, %Const{}]}] =
               Parser.parse("comptime { const a = 1; const b = 2; }").code
    end

    test "sets location correctly" do
      assert [_, %Block{location: {2, 10}}] =
               Parser.parse(~S"""
               const foo = 1;
               comptime {}
               """).code
    end
  end

  describe "general properties of a function block" do
    test "can be empty" do
      assert [%{block: %{code: []}}] = Parser.parse("fn foo() void {}").code
    end
  end
end
