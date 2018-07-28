defmodule OcapRpc.Internal.EthAccount do
  @moduledoc """
  Contract method for ABT.
  """
  alias OcapRpc.Converter
  alias OcapRpc.Eth.{Chain, Trace, Transaction}

  def tx_sent(address, num_blocks, block_offset),
    do: get_transactions(address, num_blocks, block_offset, :sent)

  def tx_received(address, num_blocks, block_offset),
    do: get_transactions(address, num_blocks, block_offset, :received)

  defp get_transactions(address, num_blocks, block_offset, direction, extra_filter \\ %{}) do
    to_block = Chain.current_block() - block_offset
    from_block = to_block - num_blocks

    address_filter =
      case direction do
        :sent -> %{from_address: [address]}
        :received -> %{to_address: [address]}
      end

    %{
      from_block: Converter.to_hex(from_block),
      to_block: Converter.to_hex(to_block),
      count: 1
    }
    |> Map.merge(address_filter)
    |> Map.merge(extra_filter)
    |> ProperCase.to_camel_case()
    |> Trace.filter()
    |> Enum.reject(fn item -> is_nil(item.transaction_hash) end)
    |> Enum.map(fn item -> Transaction.get_by_hash(item.transaction_hash) end)
  end
end
