defmodule ZigParserTest.Regressions.WhitespaceTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  # problem: the 0.16-era grammar only treated space and newline as skippable
  # whitespace, so tab-indented source (valid zig, accepted by the compiler)
  # failed to parse.  A byte order mark at the start of the file likewise
  # failed.  Zig's 0.17 grammar skips [ \n\t\r] and handles a leading BOM.

  describe "regression 03 Oct 2026" do
    test "tabs may indent" do
      assert %{code: [_]} = Parser.parse("const a = struct {\n\tx: u8,\n};")
    end

    test "tabs may separate tokens" do
      assert %{code: [_]} = Parser.parse("const\ta\t=\t1;")
    end

    test "a byte order mark may lead the file" do
      assert %{code: [_]} = Parser.parse("﻿const a = 1;")
    end

    test "carriage returns are tolerated" do
      assert %{code: [_, _]} = Parser.parse("const a = 1;\r\nconst b = 2;\r\n")
    end
  end
end
