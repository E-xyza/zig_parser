defmodule ZigParserTest.Regressions.CatchParseTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  # problem: parser doesn't seem to handle catch statements correctly

  # solution: catch operator didn't have OperatorOptions.

  describe "regression 26 Aug 2023" do
    test "catch statement without block" do
      Parser.parse("""
      pub fn my_fn(foo: u8) void {
        std.os.kill(pid, sig) catch unreachable; 
        return;
      }
      """)
    end

    test "catch statement with block" do
        Parser.parse("""
        pub fn my_fn(foo: u8) void {
          std.os.kill(pid, sig) catch {
            return;
          }; 
          return;
        }
        """)
      end
  end
end
