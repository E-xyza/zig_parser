defmodule Zig.ErrorTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.ParseError

  describe "when given a file missing a semicolon" do
    test "it throws a parser error" do
      assert_raise ParseError, fn ->
        Parser.parse("""
        const x = 10
        const y = 20;
        """)
      end
    end
  end
end
