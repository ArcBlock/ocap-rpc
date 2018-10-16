defmodule OcapRpc.Converter do
  @moduledoc """
  Utility functions for convert data
  """
  alias OcapRpc.Internal.EthTransaction

  @gwei 1_000_000_000
  @satoshi 100_000_000
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
  def to_date(nil), do: nil
  def to_date(timestamp) when is_integer(timestamp), do: DateTime.from_unix!(timestamp)

  def to_date(timestamp) do
    timestamp
    |> Hexate.to_integer()
    |> DateTime.from_unix!()
  end

  def milli_to_date(timestamp) when is_integer(timestamp),
    do: DateTime.from_unix!(timestamp, :millisecond)

  def milli_to_date(timestamp) do
    timestamp
    |> Hexate.to_integer()
    |> DateTime.from_unix!(:millisecond)
  end

  @doc """
  Convert hex string to integer
  """
  def to_int(v) when is_integer(v), do: v
  def to_int(nil), do: 0
  def to_int(""), do: 0
  def to_int("0x" <> hex), do: to_int(hex)
  def to_int(hex), do: Hexate.to_integer(hex)

  @doc """
  Convert integer to hex string
  """
  def to_hex(data), do: data |> Hexate.encode()

  def to_supply_amount(""), do: 0
  def to_supply_amount(nil), do: 0
  def to_supply_amount(total), do: to_int(total)

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

  def strip(data) when is_map(data),
    do: Enum.reduce(data, %{}, fn {k, v}, acc -> Map.put(acc, k, strip(v)) end)

  def strip(data), do: data

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

  @doc """
  Get length of array data
  """
  def len(data), do: length(data)

  def get_tx_gas_used(tx) do
    case Map.get(tx, :traces) do
      nil -> 0
      [] -> 0
      traces -> traces |> List.first() |> Map.get(:gas_used)
    end
  end

  def get_tx_fees(tx) do
    case Map.get(tx, :gas_used) do
      nil -> 0
      gas_used -> gas_used * tx.gas_price
    end
  end

  def get_tx_type(data) do
    cond do
      data.creates != nil -> "contract_deployment"
      data.to_addr_code != "" -> "contract_execution"
      true -> "normal"
    end
  end

  def calc_block_fees(data) do
    tx_list = data.transactions

    case is_map(List.first(tx_list)) do
      true ->
        Enum.reduce(tx_list, 0, fn tx, acc ->
          acc + tx.fees
        end)

      _ ->
        0
    end
  end

  def calc_block_total(data) do
    tx_list = data.transactions

    case is_map(List.first(tx_list)) do
      true -> Enum.reduce(tx_list, 0, fn tx, acc -> acc + tx.total end)
      _ -> 0
    end
  end

  def calc_block_reward(data) do
    reward =
      data.rewards
      |> Enum.filter(fn reward -> reward.reward_type == "block" end)
      |> List.first()
      |> Map.get(:value)

    reward + data.fees
  end

  def calc_uncle_reward(data) do
    data.rewards
    |> Enum.filter(fn reward -> reward.reward_type == "uncle" end)
    |> Enum.reduce(0, fn reward, acc -> acc + reward.value end)
  end

  def to_contract_value(data), do: EthTransaction.parse_input(data)

  @doc """
  Convert a bitcoin value to a satoshi value
  """
  def btc_to_satoshi(nil), do: 0
  def btc_to_satoshi(value), do: round(value * @satoshi)

  # Once parity 2.1 release with this PR: https://github.com/paritytech/parity-ethereum/pull/9194, we shall deprecated this calculation.
  def calc_tx_gas_used(trace) do
    input = String.trim_leading(trace.input || "", "0x")
    data = for <<b::binary-2 <- input>>, do: b
    zeros = Enum.count(data, &(&1 == "00"))
    non_zeros = length(data) - zeros
    21_000 + trace.raw_gas_used + zeros * 4 + non_zeros * 68
  end

  def calc_tx_status(tx) do
    last_trace = Enum.at(tx.traces, -1)

    cond do
      is_nil(last_trace) -> "error"
      is_nil(Map.get(last_trace, :error)) -> "normal"
      true -> last_trace.error |> String.downcase()
    end
  end

  def calc_block_internal_tx(block) do
    Enum.flat_map(block.transactions, &get_internal_tx/1)
  end

  def get_input_plain(data) do
    case EthTransaction.parse_input(data) do
      nil -> nil
      {signature, input} -> %{signature: signature, parameters: input}
    end
  end

  # private functions
  defp get_internal_tx(%{tx_type: "contract_execution"} = tx) do
    Enum.filter(tx.traces, fn trace ->
      trace.from == tx.to and trace.value > 0 and trace.call_type == "call"
    end)
  end

  defp get_internal_tx(_tx), do: []
end
