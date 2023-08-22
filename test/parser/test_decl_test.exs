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
  end
end
