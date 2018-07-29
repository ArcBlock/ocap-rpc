defmodule OcapRpc.Internal.EthAccount do
  @moduledoc """
  Contract method for ABT.
  """
  alias OcapRpc.Converter
  alias OcapRpc.Eth.{Account, Chain, Contract, Trace, Transaction}

  def tx_sent(address, num_blocks, block_offset),
    do: get_transactions(address, num_blocks, block_offset, :sent)

  def tx_received(address, num_blocks, block_offset),
    do: get_transactions(address, num_blocks, block_offset, :received)

  def get_by_address(address) do
    %{
      balance: Account.balance(address),
      address: address,
      is_contract: Contract.total_supply(address) != -1
    }
  end

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
      to_block: Converter.to_hex(to_block)
    }
    |> Map.merge(address_filter)
    |> Map.merge(extra_filter)
    |> ProperCase.to_camel_case()
    |> Trace.filter()
    |> Enum.reject(fn item -> is_nil(item.transaction_hash) end)
    |> Enum.map(fn item -> Transaction.get_by_hash(item.transaction_hash) end)
  end
end
