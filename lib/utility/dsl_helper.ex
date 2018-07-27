defmodule BlockchainRpc.Internal.DSLUtils do
  @moduledoc """
  Utility functions for the little DSL
  """
  alias BlockchainRpc.Eth.Trace, as: EthTtrace

  @gwei 1_000_000_000
  @ether @gwei * @gwei

  @doc """
  Decode the hext into something readable, if possible
  """
  def decode(data) do
    result = Hexate.decode(data)

    case String.printable?(result) do
      true -> result
      _ -> data
    end
  end

  @doc """
  Convert timestamp to time string
  """
  def to_date(timestamp) do
    timestamp
    |> Hexate.to_integer()
    |> DateTime.from_unix!()
    |> DateTime.to_string()
  end

  @doc """
  Convert hex string to integer
  """
  def to_int(hex), do: Hexate.to_integer(hex)

  @doc """
  Call parity RPC trace function and return the result
  """
  def trace_rpc(hash), do: EthTtrace.trace("0x#{hash}")

  @doc """
  Convert value to a value with gwei system
  """
  def to_gwei(value), do: to_int(value) / @gwei

  @doc """
  Convert value to a value with ether system
  """
  def to_ether(value), do: to_int(value) / @ether

  @doc """
  Convert code to readable data. TODO: (tchen)
  """

  def to_code("0x"), do: ""
  def to_code(code), do: code
end
