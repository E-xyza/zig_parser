if match?({:unix, _}, :os.type()) do
  defmodule ZigParserTest.EverythingHelper do
    @rejected MapSet.new(~w[
  #  PARSE TOO SLOW:
    test/_support/zig-0.15.1/src/arch/x86_64/CodeGen.zig
    test/_support/zig-0.15.1/lib/compiler_rt/udivmodti4_test.zig
  ])

    def dir_walk("test/_support/zig-0.15.1/test/cases/compile_errors" <> _), do: []

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

  parent_dir = "test/_support/zig-0.15.1"
  subdirs = ~W[lib src test]

  subdirs
  |> Stream.map(&Path.join(parent_dir, &1))
  |> Stream.flat_map(&EverythingHelper.dir_walk/1)
  |> Stream.reject(&(&1 == []))
  |> Enum.each(fn [first | _] = files ->
    dir = Path.dirname(first)

    mod =
      dir
      |> String.replace_leading(parent_dir <> "/", "")
      |> Macro.camelize()
      |> String.replace_prefix("", "Elixir.")
      |> String.to_atom()

    code =
      quote bind_quoted: binding() do
        defmodule mod do
          use ExUnit.Case, async: true
          @moduletag :everything

          describe dir do
            for file <- files do
              test file do
                unquote(file)
                |> File.read!()
                |> Zig.Parser.parse()
              end
            end
          end
        end
      end

    Code.eval_quoted(code)
  end)
end
