defmodule Zig.Parser.Test.TestDeclTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Test

  describe "the testdecl Parser.parse can" do
    test "parse an unnamed test" do
      assert [%Test{name: nil}] = Parser.parse(~S(test {})).code
    end

    test "parse a named test" do
      assert [%Test{name: "foobar"}] = Parser.parse(~S(test "foobar" {})).code
    end

    test "gets the location" do
      assert [_, %Test{location: {2, 1}}] =
               Parser.parse(~S"""
               const foo = 1;
               test "foobar" {}
               """).code
    end
  end
end
