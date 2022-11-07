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
end
