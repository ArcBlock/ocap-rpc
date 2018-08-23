defmodule OcapRpc.Converter do
  @moduledoc """
  Utility functions for convert data
  """
  alias OcapRpc.Eth.Transaction, as: EthTx
  alias OcapRpc.Internal.EthTransaction

  @gwei 1_000_000_000
  @ether @gwei * @gwei

  def gwei, do: @gwei
  def ether, do: @ether

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
  def to_int(nil), do: 0
  def to_int(""), do: 0
  def to_int("0x" <> hex), do: to_int(hex)
  def to_int(hex), do: Hexate.to_integer(hex)

  @doc """
  Convert integer to hex string
  """
  def to_hex(data), do: "0x" <> (data |> Hexate.encode())

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
  def to_ether(nil), do: 0
  def to_ether(value) when is_binary(value), do: to_int(value) / @ether
  def to_ether(value) when is_integer(value) or is_float(value), do: value / @ether

  def to_supply_amount(""), do: 0
  def to_supply_amount(nil), do: 0
  def to_supply_amount(total), do: div(to_int(total), @ether)

  @doc """
  Convert code to readable data. TODO: (tchen)
  """

  def to_code("0x"), do: ""
  def to_code(code), do: code

  @doc """
  Strip 0x for strings
  """
  def strip("0x" <> data), do: data
  def strip(data) when is_list(data), do: Enum.map(data, &strip/1)
  def strip(data), do: data

  @doc """
  Convert receipt status to integer
  """
  def to_recepit_status(nil), do: 0
  def to_recepit_status(status), do: to_int(status)

  @doc """
  Get size of the raw data
  """
  def get_size("0x" <> data), do: get_size(data)
  def get_size(data), do: div(String.length(data), 2)

  @doc """
  Get length of array data
  """
  def len(data), do: length(data)

  def get_fees(data) do
    case Map.get(data, :gas_used) do
      nil -> 0
      gas_used -> gas_used * data.gas_price
    end
  end

  def get_tx_type(data) do
    cond do
      data.creates != nil -> "contract_deployment"
      String.length(data.input) > 2 -> "contract_execution"
      true -> "normal"
    end
  end

  def calc_block_fees(data) do
    tx_list = data.transactions

    case is_map(List.first(tx_list)) do
      true -> Enum.reduce(tx_list, 0, fn tx, acc -> acc + tx.fees end)
      _ -> 0
    end
  end

  def calc_block_total(data) do
    tx_list = data.transactions

    case is_map(List.first(tx_list)) do
      true -> Enum.reduce(tx_list, 0, fn tx, acc -> acc + tx.total end)
      _ -> 0
    end
  end

  @block_reward 3 * @ether
  def calc_block_reward(data) do
    # TODO: for different height reward would be different
    @block_reward + @block_reward * length(data.uncles) / 32 + data.fees
  end

  def to_contract_value(data), do: EthTransaction.parse_input(data)

  def calc_internal_txs(data) do
    case data.tx_type do
      "contract_execution" ->
        [_ | rest] = EthTx.trace(data.hash)
        rest

      _ ->
        nil
    end
  end
end
