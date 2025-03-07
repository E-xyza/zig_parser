defmodule ZigParserTest.Regressions.SwitchParseTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Switch

  # problem: can't handle tuple types with referenced types

  describe "regression 9 May 2024" do
    test "switch can be expressions" do
      assert %{code: [%Switch{prongs: [{[:foo], {:"+=", :a, {:integer, 1}}} | _]}]} =
               Parser.parse("""
               switch (err) {
                   foo => a += 1,
                   else => |e| return e,
               }
               """)
    end
  end
end
