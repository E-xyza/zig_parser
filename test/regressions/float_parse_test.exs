defmodule ZigParserTest.Regressions.FloatParseTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  # problem: zig can handle very large (128-bit) floats
  # and elixir/BEAM can't, so it fails to parse correctly.

  # solution: punt on parsing and giving it a value, instead
  # store the super high precision float as a string.  If the
  # user would like to use a custom high precision library
  # they can do so.

  # identified by github: @jackalcooper

  describe "regression 25 Dec 2022" do
    test "zig parser can handle super long exponents" do
      assert %{code: [{:const, _, const}]} =
               Parser.parse("const foo = 1.18973149535723176502e+4932;")

      assert {:foo, _, {:extended_float, "1.18973149535723176502e+4932"}} = const
    end
  end
end
