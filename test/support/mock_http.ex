defmodule OcapRpcTest.MockHttp do
  @moduledoc false
  # credo:disable-for-this-file
  alias OcapRpcTest.TestUtils
  alias OcapRpc.Converter

  @abt_addr "0xB98d4C97425d9908E66E53A6fDf673ACcA0BE986"

  def post(_, data, _, _) do
    data = Jason.decode!(data, keys: :atoms)
    %{method: method, params: params} = data

    data =
      case method do
        "eth_getBalance" -> TestUtils.user_balance() |> encode_ether()
        "eth_getCode" -> ""
        "eth_getBlockByHash" -> get_block(params)
        "eth_getBlockByNumber" -> get_block(params)
        "eth_getTransactionByHash" -> get_tx(params)
        "eth_getTransactionByBlockNumberAndIndex" -> get_tx(params)
        "eth_getTransactionByBlockHashAndIndex" -> get_tx(params)
        "eth_getTransactionReceipt" -> TestUtils.tx_receipt()
        "eth_blockNumber" -> TestUtils.block_height()
        "eth_gasPrice" -> TestUtils.gas_price()
        "eth_call" -> eth_call(params)
        "eth_getLogs" -> eth_log(params)
        _ -> throw("error")
      end

    encode_resp(data)
  end

  defp get_block([_, false]), do: TestUtils.block()

  defp get_block([_, _]) do
    block = TestUtils.block()
    tx = TestUtils.tx()

    Map.put(block, "transactions", [tx])
  end

  defp get_tx(_), do: TestUtils.tx()

  defp eth_call([%{data: _, from: _, to: @abt_addr}]),
    do: TestUtils.user_balance() |> encode_ether()

  defp eth_call([%{data: _, to: @abt_addr}]), do: TestUtils.abt_supply()

  defp eth_log([%{topics: _, address: @abt_addr}]), do: [TestUtils.tx()]

  defp encode_ether(data), do: Converter.to_hex(data * Converter.ether())

  defp encode_resp(data) do
    {:ok, %{status_code: 200, body: Jason.encode!(%{"id" => 1, "result" => data})}}
  end
end
