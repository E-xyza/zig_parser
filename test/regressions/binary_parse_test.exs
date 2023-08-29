defmodule ZigParserTest.Regressions.BinaryParseTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Const

  # problem: can't handle unicode characters in literals

  describe "regression 29 Aug 2023" do
    test "zig parser can handle weird strings" do
      assert %{code: [%Const{value: {:char, 3}}]} =
               Parser.parse(~S"const bb = '\x03';")
    end
  end
end
