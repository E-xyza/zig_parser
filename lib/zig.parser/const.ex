defmodule Zig.Parser.Const do
  defstruct [
    :name,
    :type,
    :value,
    :location,
    :linksection,
    :addrspace,
    :doc_comment,
    pub: false,
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
