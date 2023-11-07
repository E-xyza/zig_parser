defmodule ZigParserTest.Regressions.StructParseTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Const
  alias Zig.Parser.Struct

  # zig does something wierd with structs that have both
  # fields and declarations.

  describe "regression 07 Dec 2023" do
    test "zig parser can structs with both fields and decls" do
      assert [%Const{name: :foo, value: %Struct{decls: [%Const{name: :blah}]}}] =
               Parser.parse("""
               const foo = struct{
                  value: i32,
                  const blah = 1;
               };
               """).code
    end
  end
end
