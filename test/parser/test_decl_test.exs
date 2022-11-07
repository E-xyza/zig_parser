defmodule Zig.Parser.Test.TestDeclTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  describe "the testdecl Parser.parse can" do
    test "parse an unnamed test" do
      assert [{:test, _, {nil, {:block, _, []}}}] = Parser.parse(~S(test {})).code
    end

    test "parse a named test" do
      assert [{:test, _, {"foobar", {:block, _, []}}}] = Parser.parse(~S(test "foobar" {})).code
    end

    test "parse a test with a doc comment" do
      assert [{:test, %{position: %{line: 2, column: 1}}, {"foobar", _}}] =
               Parser.parse("""
               /// this is a test
               test "foobar" {}
               """).code
    end
  end
end
