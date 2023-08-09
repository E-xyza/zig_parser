defmodule Zig.Parser.Test.BlockTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block

  # note that for these tests we're testing blocks in two cases:
  # - comptime block and function block, for simplicity.

  describe "general properties of a comptime block" do
    test "can be empty" do
      assert [:comptime, %Block{code: []}] = Parser.parse("comptime {}").code
    end

    test "location is set" do
      assert [%Block{location: {1, 11}}] = Parser.parse("comptime {}").code
    end

    test "can have a label" do
      assert [%Block{label: :foo}] = Parser.parse("comptime foo: {}").code
    end

    test "can have one statement" do
      assert [%Block{code: [{:const, _, {:a, _, _}}]}] =
               Parser.parse("comptime { const a = 1; }").code
    end

    test "can have multiple statements" do
      assert [%Block{code: [{:const, _, {:a, _, _}}, {:const, _, {:b, _, _}}]}] =
               Parser.parse("comptime foo: { const a = 1; const b = 2; }").code
    end
  end

  describe "general properties of a function block" do
    test "can be empty" do
      assert [%_{code: []}] = Parser.parse("fn foo() void {}").code
    end
  end
end
