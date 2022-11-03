defmodule Zig.Parser.Test.TopLevelComptimeTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias Zig.Parser.Block

  describe "when given a basic comptime block" do
    test "it can be found" do
      assert %Parser{toplevelcomptime: [{:block, %{comment: nil}, []}]} =
               Parser.parse("comptime {}")
    end

    test "doc comments are attached" do
      assert %Parser{
               toplevelcomptime: [
                 {:block, %{comment: " this does something\n"}, []}
               ]
             } =
               Parser.parse("""
               /// this does something
               comptime {}
               """)
    end
  end
end
