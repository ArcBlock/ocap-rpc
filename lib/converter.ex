defmodule OcapRpc.Converter do
  @moduledoc """
  Utility functions for convert data
  """
  alias OcapRpc.Eth.Trace, as: EthTtrace
  alias OcapRpc.Eth.Transaction, as: EthTx

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
  end

  @doc """
  Convert hex string to integer
  """
  def to_int("0x" <> hex), do: to_int(hex)
  def to_int(hex), do: Hexate.to_integer(hex)

  @doc """
  Convert integer to hex string
  """
  def to_hex(int), do: "0x" <> (int |> Integer.to_string(16))

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

  @doc """
  Get size of the raw data
  """
  def get_size("0x" <> data), do: get_size(data)
  def get_size(data), do: div(String.length(data), 2)

  def get_fees(data) do
    gas_used = data.hash |> EthTx.get_receipt() |> Map.get(:gas_used)

    gas_price = data.gas_price |> to_int()
    gas_used * gas_price
  end

  def get_type(_), do: "normal"
end
