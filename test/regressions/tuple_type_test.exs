defmodule ZigParserTest.Regressions.TupleTypeTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Const

  # problem: can't handle tuple types with referenced types

  # This will be fixed in a future version of zigler.

  describe "regression 29 Aug 2023" do
    @tag :skip
    test "zig parser can han" do
      assert %{code: [%Const{value: _}]} =
               Parser.parse(~S"const foo = struct { bar.baz };") |> dbg(limit: 25)
    end
  end
end
