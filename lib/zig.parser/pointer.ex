defmodule Zig.Parser.Pointer do
  defstruct [
    :alignment,
    :sentinel,
    :type,
    :count,
    :location,
    :addrspace,
    const: false,
    volatile: false,
    allowzero: false
  ]

  def parse([:LBRACKET, :RBRACKET | rest]) do
    %{parse(rest) | count: :slice}
  end

  def parse([:LBRACKET, :COLON, sentinel, :RBRACKET | rest]) do
    %{parse(rest) | count: :slice, sentinel: sentinel}
  end

  def parse([:LBRACKET, :*, :RBRACKET | rest]) do
    %{parse(rest) | count: :many}
  end

  def parse([:LBRACKET, :*, :COLON, sentinel, :RBRACKET | rest]) do
    %{parse(rest) | count: :many, sentinel: sentinel}
  end

  def parse([:LBRACKET, :*, :LETTERC, :RBRACKET | rest]) do
    %{parse(rest) | count: :c}
  end

  def parse([:* | rest]) do
    %{parse(rest) | count: :one}
  end

  def parse([{:align, alignment} | rest]) do
    %{parse(rest) | alignment: alignment}
  end

  def parse([:align, :LPAREN, alignment, :RPAREN | rest]) do
    %{parse(rest) | alignment: alignment}
  end

  def parse([
        :align,
        :LPAREN,
        alignment,
        :COLON,
        {:integer, a},
        :COLON,
        {:integer, b},
        :RPAREN | rest
      ]) do
    %{parse(rest) | alignment: {alignment, a, b}}
  end

  for qualifier <- ~w[const volatile allowzero]a do
    def parse([unquote(qualifier) | rest]) do
      %{parse(rest) | unquote(qualifier) => true}
    end
  end

  for property <- ~w[addrspace]a do
    def parse([{unquote(property), value} | rest]) do
      %{parse(rest) | unquote(property) => value}
    end
  end

  def parse([:QUESTIONMARK, type]) do
    parse([{:optional, type}])
  end

  def parse([type]), do: %__MODULE__{type: type}
end
