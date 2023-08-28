defmodule ZigParserTest.EverythingHelper do
  def dir_walk(dir) do
    dir
    |> File.ls!()
    |> Enum.flat_map(fn file_or_dir ->
      full_path = Path.join(dir, file_or_dir)

      cond do
        File.dir?(full_path) -> dir_walk(full_path)
        Path.extname(full_path) == ".zig" -> [full_path]
        true -> []
      end
    end)
  end
end

defmodule ZigParserTest.EverythingTest do
  use ExUnit.Case, async: true

  alias Zig.Parser
  alias ZigParserTest.EverythingHelper

  @moduletag :everything

  parent_dir = "test/_support/zig-0.11.0"
  subdirs = ~W[lib src test]

  all_files =
    subdirs
    |> Enum.map(&Path.join(parent_dir, &1))
    |> Enum.flat_map(&EverythingHelper.dir_walk/1)

  for file <- all_files do
    test file do
      unquote(file)
      |> File.read!()
      |> Parser.parse()
    end
  end
end
