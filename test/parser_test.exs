defmodule Zig.ParserTest do
  use ExUnit.Case, async: true

  alias Zig.Parser

  describe "when given a file with a top-level doc comment" do
    test "a one-liner works" do
      assert " hi this is a doc comment\n" =
               Parser.parse("""
               //! hi this is a doc comment
               """).doc_comment
    end

    test "a multiliner works" do
      assert " this is line 1\n this is line 2\n" =
               Parser.parse("""
               //! this is line 1
               //! this is line 2
               """).doc_comment
    end
  end

  describe "when given a file with a test" do
    test "one test can be found" do
      assert [{:test, _, {"foo", {:block, _, []}}}] = Parser.parse(~s(test "foo" {})).code
    end

    test "multiple tests can be found" do
      assert [{:test, _, {"foo", _}}, {:test, _, {"bar", _}}] =
               Parser.parse(~s(test "foo" {}\ntest "bar" {})).code
    end
  end

  describe "dependencies can be found" do
    test "with a single toplevel @import" do
      assert ["foo.zig"] = Parser.parse(~S[const foo = @import("foo.zig");]).dependencies
    end

    test "when multiple toplevel @import" do
      assert ["foo.zig", "bar.zig"] =
               Parser.parse(~S[const foo = @import("foo.zig"); const bar = @import("bar.zig");]).dependencies
    end

    test "builtin stuff (no .zig extension) is ignored" do
      assert [] = Parser.parse(~S[const std = @import("std");]).dependencies
    end

    test "with @embedFile" do
      assert ["somefile.json"] =
               Parser.parse(~S[const file = @embedFile("somefile.json");]).dependencies
    end

    test "can't identify if it's not a literal" do
      assert [] = Parser.parse(~S[const std = @import(content);]).dependencies
    end
  end

  describe "line comments are logged" do
    test "no comments" do
      assert [] = Parser.parse("""
      pub fn main() void {}
      """).comments
    end

    test "one comment" do
      assert [{" this is a comment\n", %{line: 1, column: 1}}] = Parser.parse("""
      // this is a comment
      pub fn main() void{}
      """).comments
    end

    test "two comments" do
      assert [{" this is a comment\n", %{line: 1, column: 1}}, {" this is another comment\n", %{line: 3, column: 2}}] = Parser.parse("""
      // this is a comment
      pub fn main() void{}
        // this is another comment
      """).comments
    end
  end
end
