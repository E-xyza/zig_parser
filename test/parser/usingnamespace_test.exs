defmodule Zig.Parser.Test.UsingNamespaceTest do
  use ExUnit.Case, async: true

  # tests:
  # Usingnamespace <- KEYWORD_usingnamespace Expr SEMICOLON
  # and all of the pieces that come with this part of the function proto.

  alias Zig.Parser

  describe "when given a basic usingnamespace block" do
    test "it can be found" do
      assert %Parser{usingnamespace: [:foo]} =
               Parser.parse("""
               usingnamespace foo;
               """)
    end
  end
end
