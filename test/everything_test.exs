defmodule ZigParserTest.EverythingHelper do
  @rejected MapSet.new(~w[
    PARSE TOO SLOW:
    test/_support/zig-0.11.0/lib/compiler_rt/udivmodti4_test.zig
    test/_support/zig-0.11.0/lib/compiler_rt/udivmoddi4_test.zig

    BROKEN STRING LITERALS:
    test/_support/zig-0.11.0/test/behavior/translate_c_macros.zig
  ])

  def dir_walk("test/_support/zig-0.11.0/test/cases/compile_errors/" <> _), do: []

  def dir_walk(dir) do
    {dirs, files} =
      dir
      |> File.ls!()
      |> Enum.map(&Path.join(dir, &1))
      |> Enum.split_with(&File.dir?/1)

    zig_files =
      files
      |> Enum.filter(&(Path.extname(&1) == ".zig"))
      |> Enum.reject(&(&1 in @rejected))

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

    mod =
      dir
      |> String.replace_leading(parent_dir <> "/", "")
      |> Macro.camelize()
      |> String.to_atom()

    code =
      quote bind_quoted: binding() do
        defmodule mod do
          use ExUnit.Case, async: true
          @moduletag :everything

          describe dir do
            for file <- files do
              test file do
                # try do
                unquote(file)
                |> File.read!()
                |> Zig.Parser.parse()

                # rescue
                #  e in FunctionClauseError ->
                #    if e.module == Zig.Parser.Statement and e.function == :parse do
                #      IO.puts(IO.ANSI.yellow() <> unquote(file) <> IO.ANSI.reset())
                #    end
                # end
              end
            end
          end
        end
      end

    Code.eval_quoted(code)
  end)
