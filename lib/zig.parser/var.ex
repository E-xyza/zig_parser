defmodule Zig.Parser.Var do
  defstruct [
    :name,
    :type,
    :value,
    :location,
    :doc_comment,
    :align,
    extern: false,
    export: false,
    pub: false,
    threadlocal: false,
    comptime: false
  ]

  def parse([:COLON, type | rest]) do
    %{parse(rest) | type: type}
  end

  def parse([:=, value, :SEMICOLON]) do
    %__MODULE__{value: value}
  end

  def parse([name | rest]) do
    %{parse(rest) | name: name}
  end
end
