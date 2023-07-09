# Zig.Parser

Parses Zig files.

Note: This version of Zig.Parser is pinned to Zig 0.10.x and the entire 
architecture will be rewritten on Zig 0.11.x.  Until the architecture is
revised, do NOT rely on the data structures emitted by Zig.Parser.

Future versions of Zig.Parser will be pinned to Zig version releases, so that
The Zig PEG spec will be kept in-line, the version it's pinned to will be 
notated here.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `zig_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:zig_parser, "~> 0.1.8"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/zig_parser>.

