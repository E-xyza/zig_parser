defmodule Zig.Parser.Test.BlockTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block
  alias Zig.Parser.Const

  # this test (ab)uses the comptime block to track block information

  describe "general properties of a comptime block" do
    test "can be empty" do
      assert %Parser{toplevelcomptime: [{:block, %{label: nil}, []}]} =
               Parser.parse("comptime {}")
    end

    test "can have a label" do
      assert %Parser{toplevelcomptime: [{:block, %{label: :foo}, []}]} =
               Parser.parse("comptime foo: {}")
    end

    test "can have one statement" do
      assert %Parser{toplevelcomptime: [{:block, %{label: :foo}, [%Const{name: :a}]}]} =
               Parser.parse("comptime foo: { const a = 1; }")
    end

    test "can have multiple statements" do
      assert %Parser{
               toplevelcomptime: [{:block, %{label: :foo}, [%Const{name: :a}, %Const{name: :b}]}]
             } = Parser.parse("comptime foo: { const a = 1; const b = 2; }")
    end
  end
end
