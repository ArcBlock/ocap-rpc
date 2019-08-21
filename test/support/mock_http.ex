defmodule OcapRpcTest.MockHttp do
  @moduledoc false
  # credo:disable-for-this-file
  alias OcapRpcTest.TestUtils

  alias OcapRpc.Converter

  @abt_addr "0xb98d4c97425d9908e66e53a6fdf673acca0be986"

  def post(data) do
    data = Jason.decode!(data, keys: :atoms)

    batch? = is_list(data)

    %{method: method, params: params} =
      case batch? do
        true -> List.first(data)
        _ -> data
      end

    data =
      case method do
        "eth_getBalance" -> TestUtils.user_balance() |> Converter.to_hex()
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
        "trace_block" -> TestUtils.block_trace()
        "trace_transaction" -> TestUtils.tx_trace()
        _ -> throw("error")
      end

    encode_resp(data, batch?)
  end

  defp get_block([_, false]), do: TestUtils.block()

  defp get_block([_, _]) do
    block = TestUtils.block()
    tx = TestUtils.tx()

    Map.put(block, "transactions", [tx])
  end

  defp get_tx(_), do: TestUtils.tx()

  defp eth_call([%{data: _, from: _, to: @abt_addr}]),
    do: TestUtils.user_balance() |> Converter.to_hex()

  defp eth_call([%{data: _, to: @abt_addr}]), do: TestUtils.abt_supply()

  defp eth_log([%{topics: _, address: @abt_addr}]), do: [TestUtils.tx()]

  defp encode_resp(data, false) do
    %{"id" => 1, "result" => data}
  end

  defp encode_resp(data, true) do
    [%{"id" => 1, "result" => data}]
  end
end
