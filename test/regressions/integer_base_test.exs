defmodule ZigParserTest.Regressions.IntegerBaseTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Const

  # problem: binary (0b-prefixed) integer literals were parsed with
  # String.to_integer/2 using base 16 instead of base 2, so `0b1010`
  # came back as 4112 instead of 10.

  describe "regression 03 Oct 2026" do
    test "binary literals use base 2" do
      assert %{code: [%Const{value: {:integer, 10}}]} = Parser.parse("const a = 0b1010;")
      assert %{code: [%Const{value: {:integer, 255}}]} = Parser.parse("const a = 0b11111111;")
    end

    test "binary literals may contain underscores" do
      assert %{code: [%Const{value: {:integer, 255}}]} = Parser.parse("const a = 0b1111_1111;")
    end

    test "the other bases are unaffected" do
      assert %{code: [%Const{value: {:integer, 255}}]} = Parser.parse("const a = 0xff;")
      assert %{code: [%Const{value: {:integer, 15}}]} = Parser.parse("const a = 0o17;")
      assert %{code: [%Const{value: {:integer, 42}}]} = Parser.parse("const a = 42;")
    end
  end
end
