defmodule ZigParserTest.EverythingHelper do
  @rejected MapSet.new(~w[
    PARSE TOO SLOW:
    test/_support/zig-0.11.0/lib/compiler_rt/udivmodti4_test.zig
    test/_support/zig-0.11.0/lib/compiler_rt/udivmoddi4_test.zig

    BROKEN STRING/NUMBER LITERALS:
    test/_support/zig-0.11.0/test/behavior/translate_c_macros.zig
    test/_support/zig-0.11.0/test/behavior/ptrcast.zig
    test/_support/zig-0.11.0/test/behavior/basic.zig
    test/_support/zig-0.11.0/src/print_zir.zig
    test/_support/zig-0.11.0/src/print_air.zig
    test/_support/zig-0.11.0/src/print_env.zig
    test/_support/zig-0.11.0/src/translate_c.zig
    test/_support/zig-0.11.0/src/print_targets.zig
    test/_support/zig-0.11.0/test/cases/assert_function.14.zig
    test/_support/zig-0.11.0/test/cases/assert_function.13.zig
    test/_support/zig-0.11.0/src/AstGen.zig
    test/_support/zig-0.11.0/test/behavior/bugs/6456.zig
    test/_support/zig-0.11.0/src/Sema.zig
    test/_support/zig-0.11.0/src/codegen/c.zig
    test/_support/zig-0.11.0/test/src/Cases.zig
    test/_support/zig-0.11.0/test/src/check-stack-trace.zig
    test/_support/zig-0.11.0/test/standalone/child_process/child.zig
    test/_support/zig-0.11.0/test/standalone/child_process/main.zig
    test/_support/zig-0.11.0/src/libc_installation.zig
    test/_support/zig-0.11.0/src/link/tapi/Tokenizer.zig
    test/_support/zig-0.11.0/src/link/tapi/parse.zig
    test/_support/zig-0.11.0/src/link/tapi/yaml.zig
    test/_support/zig-0.11.0/src/codegen/spirv/Assembler.zig
    test/_support/zig-0.11.0/src/translate_c/ast.zig
    test/_support/zig-0.11.0/src/windows_sdk.zig
    test/_support/zig-0.11.0/src/Autodoc.zig
    test/_support/zig-0.11.0/src/autodoc/render_source.zig
    test/_support/zig-0.11.0/src/Package.zig
    test/_support/zig-0.11.0/lib/std/zig/string_literal.zig
    test/_support/zig-0.11.0/lib/std/zig/fmt.zig
    test/_support/zig-0.11.0/lib/std/zig/render.zig
    test/_support/zig-0.11.0/lib/std/zig/Parse.zig
    test/_support/zig-0.11.0/lib/std/zig/system/NativeTargetInfo.zig
    test/_support/zig-0.11.0/lib/std/zig/ErrorBundle.zig
    test/_support/zig-0.11.0/lib/std/zig/system/linux.zig
    test/_support/zig-0.11.0/lib/std/json/stringify.zig
    test/_support/zig-0.11.0/lib/std/Build/Cache.zig
    test/_support/zig-0.11.0/lib/std/os/windows.zig
    test/_support/zig-0.11.0/lib/std/zig/Ast.zig
    test/_support/zig-0.11.0/lib/std/zig.zig
    test/_support/zig-0.11.0/lib/std/tz.zig
    test/_support/zig-0.11.0/lib/std/os.zig 
    test/_support/zig-0.11.0/lib/std/Build/Cache/DepTokenizer.zig
    test/_support/zig-0.11.0/lib/std/c/tokenizer.zig
    test/_support/zig-0.11.0/lib/std/Build.zig
    test/_support/zig-0.11.0/lib/std/ascii.zig
    test/_support/zig-0.11.0/lib/std/testing.zig
    test/_support/zig-0.11.0/lib/std/io/reader.zig
    test/_support/zig-0.11.0/lib/std/fmt.zig
    test/_support/zig-0.11.0/lib/std/child_process.zig
    test/_support/zig-0.11.0/lib/std/dynamic_library.zig
    test/_support/zig-0.11.0/lib/std/process.zig
    test/_support/zig-0.11.0/lib/std/Uri.zig
    test/_support/zig-0.11.0/lib/std/debug.zig
    test/_support/zig-0.11.0/lib/std/fs/path.zig
    test/_support/zig-0.11.0/lib/std/http/protocol.zig
    test/_support/zig-0.11.0/lib/std/mem.zig
    test/_support/zig-0.11.0/lib/ssp.zig
    test/_support/zig-0.11.0/lib/std/Build/Step/Compile.zig
    test/_support/zig-0.11.0/lib/std/Build/Step/CheckObject.zig
    test/_support/zig-0.11.0/lib/std/http/Server.zig
    test/_support/zig-0.11.0/lib/std/http/Client.zig
    test/_support/zig-0.11.0/src/arch/x86_64/encoder.zig
    test/_support/zig-0.11.0/lib/std/zig/tokenizer.zig
    test/_support/zig-0.11.0/lib/std/Progress.zig
    test/_support/zig-0.11.0/lib/std/net.zig
    test/_support/zig-0.11.0/src/Module.zig
    test/_support/zig-0.11.0/src/codegen/llvm/Builder.zig
    test/_support/zig-0.11.0/lib/std/json/scanner.zig
    test/_support/zig-0.11.0/lib/std/Build/Step/ConfigHeader.zig
  ])

  def dir_walk("test/_support/zig-0.11.0/test/cases/compile_errors" <> _), do: []

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
              try do
                unquote(file)
                |> File.read!()
                |> Zig.Parser.parse()
              rescue
                e in FunctionClauseError ->
                  unless e.module == Zig.Parser.Asm do
                    reraise e, __STACKTRACE__
                  end
              end
            end
          end
        end
      end
    end

  Code.eval_quoted(code)
end)
