defmodule OcapRpc.Internal.Erc20 do
  @moduledoc """
  Contract method for ABT.
  """
  alias OcapRpc.Converter
  alias OcapRpc.Eth.Chain
  alias OcapRpc.Internal.{EthRpc, Utils}

  @contract_addrs %{
    abt: "0xB98d4C97425d9908E66E53A6fDf673ACcA0BE986",
    ae: "0x5ca9a71b1d01849c0a95490cc00559717fcf0d1d",
    aion: "0x4CEdA7906a5Ed2179785Cd3A40A69ee8bc99C466",
    ctxc: "0xea11755ae41d889ceec39a63e6ff75a02bc1c00d"
  }

  @method_sigs [
                 "approve(address,uint256)",
                 "transferFrom(address,address,uint256)",
                 "unpause()",
                 "decreaseApproval(address,uint256)",
                 "pause()",
                 "transfer(address,uint256)",
                 "increaseApproval(address,uint256)",
                 "transferOwnership(address)"
               ]
               |> Enum.reduce(%{}, fn name, acc ->
                 sig = "0x" <> Utils.get_method_sig(name)
                 fn_name = name |> String.split("(") |> List.first()
                 arity = name |> String.split(",") |> length()
                 Map.put(acc, sig, {fn_name, arity, name})
               end)

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
    |> post_processing()
  end

  defp get_tx(hash), do: EthRpc.request("eth_getTransactionByHash", [hash])
  defp call(data), do: EthRpc.request("eth_call", [data])
  defp get_logs(data), do: EthRpc.request("eth_getLogs", [data])

  defp post_processing(data) when is_list(data) do
    data
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&post_processing/1)
  end

  defp post_processing(%{"input" => "0x"} = data), do: data

  defp post_processing(data) when is_map(data) do
    <<sig::binary-10, rest::binary>> = data["input"]

    {method, _arity, fn_sig} =
      case Map.get(@method_sigs, sig) do
        nil -> {"unknownMethod", 0, "n/a"}
        v -> v
      end

    args = get_args(rest)
    input_plain = get_input_plain(fn_sig, sig, args)

    case method do
      "transfer" ->
        [to, value] = args

        update_tx(data, data["from"], to, value, input_plain)

      "transferFrom" ->
        [from, to, value] = args
        update_tx(data, from, to, value, input_plain)

      _ ->
        data
    end
  end

  defp update_tx(data, from, to, value, input) do
    data
    |> Map.put("contractFrom", from)
    |> Map.put("contractTo", to)
    |> Map.put("contractValue", value)
    |> Map.put("inputPlain", input)
  end

  defp get_input_plain(fn_sig, sig, args) do
    args
    |> Enum.with_index()
    |> Enum.reduce("Function: #{fn_sig}\nMethodID: #{sig}", fn {item, idx}, acc ->
      acc <> "\n[#{idx}]: #{item}"
    end)
  end

  defp get_args(data),
    do: for(<<arg::binary-64 <- data>>, do: "0x" <> (arg |> String.trim_leading("0")))
end
