defmodule Zig.Parser.Test.BlockTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  # this test (ab)uses the comptime block to quickly jump into a block statement

  defmacrop toplevelblockcontent(
              to_bind,
              options \\ quote do
                _
              end
            ) do
    quote do
      [{:comptime, _, {:block, unquote(options), unquote(to_bind)}}]
    end
  end

  describe "general properties of a comptime block" do
    test "can be empty" do
      assert toplevelblockcontent([]) = Parser.parse("comptime {}").code
    end

    test "can have a label" do
      assert toplevelblockcontent([], %{label: :foo}) = Parser.parse("comptime foo: {}").code
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
