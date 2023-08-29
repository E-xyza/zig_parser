defmodule ZigParserTest.EverythingHelper do
  def dir_walk(dir) do
    {dirs, files} = dir
    |> File.ls!()
    |> Enum.map(&Path.join(dir, &1))
    |> Enum.split_with(&File.dir?/1)

    zig_files = Enum.filter(files, &Path.extname(&1) == ".zig")

    [zig_files | Enum.flat_map(dirs, &dir_walk(&1))]
  end
end

alias ZigParserTest.EverythingHelper

parent_dir = "test/_support/zig-0.11.0"
subdirs = ~W[lib src test]

all_files =
  subdirs
  |> Enum.map(&Path.join(parent_dir, &1))
  |> Enum.flat_map(&EverythingHelper.dir_walk/1)
  |> Enum.reject(&(&1 == []))
  |> Enum.each(fn [first | _] = files ->
    dir = Path.dirname(first)

    mod = dir
    |> String.replace_leading(parent_dir <> "/", "")
    |> Macro.camelize
    |> String.to_atom

    code = quote bind_quoted: binding() do
      defmodule mod do
        use ExUnit.Case, async: true
        @moduletag :everything

        describe dir do

          for file <- files do
            test file do
              try do
                unquote(file)
                |> File.read!
                |> Zig.Parser.parse
              rescue
                e in FunctionClauseError ->
                  if unquote(file) =~ "test/_support/zig-0.11.0/test" do
                    IO.puts(unquote(file))
                  end
              end
            end
          end
        end
      end
    end

    Code.eval_quoted(code)
  end)
