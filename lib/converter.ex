defmodule OcapRpc.Converter do
  @moduledoc """
  Utility functions for convert data
  """
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
  def to_int(nil), do: -1
  def to_int("0x" <> hex), do: to_int(hex)
  def to_int(hex), do: Hexate.to_integer(hex)

  @doc """
  Convert integer to hex string
  """
  def to_hex(int), do: "0x" <> (int |> Integer.to_string(16))

  @doc """
  Call parity RPC trace function and return the result
  """
  def trace_rpc(hash), do: EthTx.trace("0x#{hash}")

  @doc """
  Convert value to a value with gwei system
  """
  def to_gwei(value), do: to_int(value) / @gwei

  @doc """
  Convert value to a value with ether system
  """
  def to_ether(value), do: to_int(value) / @ether

  def to_supply_amount(""), do: -1
  def to_supply_amount(nil), do: -1
  def to_supply_amount(total), do: to_ether(total)

  @doc """
  Convert code to readable data. TODO: (tchen)
  """

  def to_code("0x"), do: ""
  def to_code(code), do: code

  @doc """
  Convert receipt status to integer
  """
  def to_recepit_status(nil), do: 1
  def to_recepit_status(status), do: to_int(status)

  @doc """
  Get size of the raw data
  """
  def get_size("0x" <> data), do: get_size(data)
  def get_size(data), do: div(String.length(data), 2)

  def get_fees(data) do
    case Map.get(data, :gas_used) do
      nil -> nil
      gas_used -> to_int(gas_used) * to_int(data.gas_price)
    end
  end

  def get_tx_type(data) do
    cond do
      data.creates != nil -> "contract_deployment"
      String.length(data.input) > 2 -> "contract_execution"
      true -> "normal"
    end
  end

  def calc_block_fees(_data) do
    -1
  end

  def calc_block_reward(_data) do
    -1
  end
end
