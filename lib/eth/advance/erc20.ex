defmodule OcapRpc.Internal.Erc20 do
  @moduledoc """
  Contract method for ABT.
  """
  alias OcapRpc.Converter
  alias OcapRpc.Eth.Chain
  alias OcapRpc.Internal.{EthRpc, EthTransaction, Utils}

  @contract_addrs %{
    abt: "b98d4c97425d9908e66e53a6fdf673acca0be986",
    ae: "5ca9a71b1d01849c0a95490cc00559717fcf0d1d",
    aion: "4ceda7906a5ed2179785cd3a40a69ee8bc99c466",
    ctxc: "ea11755ae41d889ceec39a63e6ff75a02bc1c00d"
  }

  def transfer(contract, private_key, to, value, opts) do
    contract_addr = Map.get(@contract_addrs, contract, contract)
    receiver = Utils.hex_to_binary(to)

    input =
      "transfer(address,uint256)"
      |> ABI.encode([receiver, value])
      |> Base.encode16(case: :lower)

    opts =
      opts
      # According to existing data, it never uses more than 29117 gas when calling this API.
      |> Keyword.put_new(:gas_limit, 30_000)
      |> Keyword.put(:input, input)

    EthTransaction.send_transaction(private_key, contract_addr, 0, opts)
  end

  def balance_of(nil, _), do: 0

  def balance_of(token, from) when is_atom(token) do
    contract_addr = Map.get(@contract_addrs, token)
    balance_of(contract_addr, from)
  end

  def balance_of(addr, from) do
    %{
      from: from,
      to: addr,
      data: Utils.sig_balance_of(from)
    }
    |> ProperCase.to_camel_case()
    |> call()
  end

  def total_supply(nil), do: 0

  def total_supply(token) when is_atom(token) do
    contract_addr = Map.get(@contract_addrs, token)
    total_supply(contract_addr)
  end

  def total_supply(addr) do
    %{
      to: addr,
      data: Utils.sig_total_supply()
    }
    |> ProperCase.to_camel_case()
    |> call()
  end

  def get_transactions(nil, _from, _to, _num_blocks, _block_offset), do: []

  def get_transactions(token, from, to, num_blocks, block_offset) when is_atom(token) do
    contract_addr = Map.get(@contract_addrs, token)
    get_transactions(contract_addr, from, to, num_blocks, block_offset)
  end

  def get_transactions(addr, from, to, num_blocks, block_offset) do
    to_block = Chain.current_block() - block_offset
    from_block = to_block - num_blocks

    filter = %{
      from_block: Converter.to_hex(from_block),
      to_block: Converter.to_hex(to_block)
    }

    from = Utils.addr_to_topic(from)
    to = Utils.addr_to_topic(to)

    %{
      topics: [nil, from, to],
      address: addr
    }
    |> Map.merge(filter)
    |> ProperCase.to_camel_case()
    |> get_logs()
    |> Enum.map(fn item -> get_tx(item["transactionHash"]) end)
  end

  defp get_tx(hash),
    do: "eth_getTransactionByHash" |> EthRpc.call([hash]) |> EthRpc.resp_hook(:transaction)

  defp call(data), do: EthRpc.call("eth_call", [data])
  defp get_logs(data), do: EthRpc.call("eth_getLogs", [data])
end
