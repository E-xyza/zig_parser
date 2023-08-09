defmodule Zig.Parser.Test.BlockTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  # this test (ab)uses the comptime block to quickly jump into a block statement

  defmacrop toplevelblockcontent(block, props \\ []) do
    quote do
      [{:comptime, :aa, %Zig.Parser.Block{unquote_splicing(props ++ [block: block])}}]
    end
  end

  describe "general properties of a comptime block" do
    test "can be empty" do
      toplevelblockcontent([]) |> dbg(limit: 25)
      Parser.parse("comptime {}").code |> dbg(limit: 25)
      # assert toplevelblockcontent([]) =
    end

    test "can have a label" do
      assert toplevelblockcontent([], label: :foo) = Parser.parse("comptime foo: {}").code
    end

    test "can have one statement" do
      assert toplevelblockcontent([{:const, _, {:a, _, _}}]) =
               Parser.parse("comptime { const a = 1; }").code
    end

    test "can have multiple statements" do
      assert toplevelblockcontent([{:const, _, {:a, _, _}}, {:const, _, {:b, _, _}}]) =
               Parser.parse("comptime foo: { const a = 1; const b = 2; }").code
    end
  end
end
